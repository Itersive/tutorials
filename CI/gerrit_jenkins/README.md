# Gerrit with Jenkins on Docker

Two tools with fast and simple setup for CI/CD in Git projects.

# Prerequisites

* Docker and docker-compose
* Terminal
* Web browser

# Steps

* Prepare docker-compose.yml file:

```
version: '3'

services:
  # Gerrit
  gerrit:
    image: gerritcodereview/gerrit
    volumes:
       - git-volume:/var/gerrit/git
       - index-volume:/var/gerrit/index
       - cache-volume:/var/gerrit/cache
    ports:
       - "29418:29418"
       - "8080:8080"
    container_name: gerrit

  # Jenkins
  jenkins:
    image: jenkins/jenkins # to use the latest weekly or jenkins/jenkins:lts to use latest LTS
    volumes:
      - jenkins_home:/var/jenkins_home
    ports:
      - "50000:50000"
      - "8081:8080"
    links:
      - gerrit
    container_name: jenkins


volumes:
  git-volume:
  index-volume:
  cache-volume:
  jenkins_home:
```

This file contains 2 services - gerrit and jenkins and 4 volumes which are used in mentioned services for saving data between restarts.

* Run it:

```
docker-compose up -d
```

Expected output:
```
Creating network "gerritjenkins_default" with the default driver
Creating volume "gerritjenkins_jenkins_home" with default driver
Creating volume "gerritjenkins_git-volume" with default driver
Creating volume "gerritjenkins_index-volume" with default driver
Creating volume "gerritjenkins_cache-volume" with default driver
Creating gerrit ... 
Creating gerrit ... done
Creating jenkins ... 
Creating jenkins ... done
```

```
> docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                              NAMES
b52558a7e3ce        jenkins/jenkins           "/sbin/tini -- /usr/…"   30 seconds ago      Up 28 seconds       0.0.0.0:50000->50000/tcp, 0.0.0.0:8081->8080/tcp   jenkins
baeb12850bd5        gerritcodereview/gerrit   "/bin/sh -c 'git con…"   31 seconds ago      Up 30 seconds       0.0.0.0:8080->8080/tcp, 0.0.0.0:29418->29418/tcp   gerrit

```

* Open gerrit and jenkins in web browser

```
http://localhost:8080 - gerrit
http://localhost:8081 - jenkins
```

* Jenkins - create admin account and install plugins:
    * password - find it in `docker logs jenkins` or in `/var/jenkins_home/secrets/initialAdminPassword` in jenkins container
    * default plugins should be enough but if you want you can choose which plugins should be installed
    * create admin account
    * leave Jenkins URL as `http://localhost:8081/`
    * required plugins: gerrit trigger, gerrit code review, gerrit verify status reporter - `http://localhost:8081/pluginManager/available` (restart is not needed)

* Gerrit - create repository and configure accounts:;
    * should be logged on admin account
    * in this tutorial we are not using any authentication service - all credentials are stored in H2 base and passwords are generated. Go to `http://localhost:8080/settings/#HTTPCredentials` and save your password for admin account
    * logout and register new account, in my case it's `jenkins`, and save password
    * go to bash in jenkins container: `docker exec -it jenkins bash`
    * go to `/var/jenkins_home`
    * generate ssh keys: `ssh-keygen -t rsa` and copy `id_rsa.pub` to gerrit: `http://localhost:8080/settings/#SSHKeys`
    * login to admin account and add `jenkins` to `Non-Interactive Users` group: `http://localhost:8080/admin/groups/2,members`
    * create new group `Event Streaming Users` and add `jenkins` to it
    * in `http://localhost:8080/admin/repos/All-Projects,access` add this group to `Stream Events` in `Global Capabilities`
    * create repository - `http://localhost:8080/admin/repos`
    * go to repository settings and in `Access` and add:
        * `Read` permission for `Non-Iteractive Users` group
        * add reference `refs/heads/*` and add `Label Code-Review` from -1 to 1 for `Non-Iteractive Users` group

* Configure gerrit trigger plugin:
    * on `http://localhost:8081/gerrit-trigger/` add new server
    * name it and mark `Gerrit Server with Default Configurations`
    * hostname - `gerrit`, frontend URL - `http://gerrit:8080`, username - `jenkins`
    * test connection - should be ok
    * in Code Review section set `Successful` to 1 and `Failed` to -2
    * go to advanced settings and mark `Use REST API`
    * use saved credentials from Gerrit for `jenkins` account and test connection - should be ok
    * save and click `Status` button for your server - version of server should be visible
    
* Configure first job:
    * on `http://localhost:8081/view/all/newJob` choose default project
    * in triggers mark `Gerrit event`, choose server, trigger and project (all project should be visible in list), my setup:
    ![Gerrit Trigger](/gerrit_trigger.png)
    * add `Execute shell` in build section with for example `echo $GERRIT_CHANGE_SUBJECT`
    * save

* Test it
    * from `http://localhost:8080/admin/repos/your_repository_name` get command for cloning repository with commit-msg hook (I didn't set proper URL for Gerrit and now we have to fix URL in this command, change it to localhost:8080)
    * there should be only one commit
    ```
    > git log
    commit c04bece9bbee4831d33439108cdec45064ddd90d (HEAD -> master, origin/master, origin/HEAD)
    Author: Administrator <admin@example.com>
    Date:   Fri Dec 14 17:04:24 2018 +0000

    Initial empty repository
    ```
    * make some changes, for example create empty file `test`
    * `git add test`
    * `git commit` and add message
    * `git push origin HEAD:refs/for/master` - push it to repository
    * last commit should have additional `Change-Id` in commmit message

* Check results
    * Jenkins: in job history should be one triggered job by our change and in logs commit message should be printed
    * Gerrit: on `http://localhost:8080/dashboard/self` should be one `Outgoing review` and in it should be few comments added by jenkins user (and +1 in Code Review added by jenkins too)
    * Click `Code Review +2` on this change and then submit it - now this change is merged to master branch
    
* Improve this Jenkins job:
    * create new repository - in my case it's `pipelines`
    * clone it and add new file `Jenkinsfiles`
    * add there this code
    ```
    node {
        stage('First stage') {
            print 'Hello world'
        }
        
        stage('Second stage') {
            print params.GERRIT_CHANGE_SUBJECT
        }
    }
    ```
    * add, commit and push it to gerrit
    * give +2 and submit change on gerrit
    * go to Jenkins
    * on `http://localhost:8081/credentials/store/system/domain/_/newCredentials` add new credentials for jenkins user from gerrit
    * create new job with type `Pipeline`
    * set the same type of trigger as in first job
    * in `Pipeline` section choose `Pipeline script from SCM` and choose git
    * set repository URL to `http://gerrit:8080/pipelines`, set credentials and save configuration
    * make new change in first repository and push it to gerrit
    * check results - both jobs should be triggered
    
# Summary

In this tutorial I presented how to setup Gerrit with Jenkins on Docker. There is much more options and possibilities - this is only basic setup for quick start.
All data is stored in docker volumes and after restarts or even `docker-compose down` data will be safe. 
