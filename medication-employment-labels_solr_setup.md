## Ensure that Solr is installed & a core has been created

TODO: Solr's role within medication mapping, download URL, basic requirements



Solr should be running on the same computer that will be running the TURBO medication mapping knowledgebase build code, or it can run on another computer as long as the necessary TCP port is open.



The PennTURBO team is currently using Solr 8.5.1. We have also had good results with late 7.x versions.



Oracle Corporation OpenJDK 64-Bit Server VM 1.8.0_252 25.252-b09



Some of these steps may require that the user has administrative privileges on the Solr server. For example, running the Solr process and writing to the Solr data path.



Solr has a rest API as well as a web console. Start by  checking if the Solr server is running. One way is visiting 



`http://<solr server address>:<Solr port>`

Where the default port is 8983

If the Solr web console doesn't appear, you could also run



`ps -ef | grep Solr` 



on a Unix-like system



or 



`<Solr home>/bin/Solr status`



The PennTURBO team has been using `/opt/Solr` as the Solr home.



If it is not running, you will need to decide whether to run Solr in cloud mode. The PennTURBO team has been running Solr in standalone mode, not cloud mode. To start Solr in standalone mode, run a command lie this



`<Solr home>/bin/Solr start`

Common arguments to this command include increasing the Java heap memory and specifying the Solr data path



-Dsolr.solr.home=/var/Solr/data

-Xmx512m



In Solr standalone mode, documents are indexed into databases called cores. Therefore, ensure that the core specified in CONFIGURATION FILE creates. That can be done by clicking on the "select a n option" button on the Solr web console's home page, or by pining over REST/CURL etc.



`http://localhost:8983/solr/<core name>/ping`



If the core does not exist, create it with a command like this

`<Solr home>/bin/Solr create -c <core name>`



TODO customizastions & "reload" before laoding data?

----



rxnav_med_mapping_load_materialize_etc.R



List libraries



bootstraps the configuration from a GitHub Gist at https://gist.github.com/turbomam/f082295aafb95e71d109d15ca4535e46

the devtools library must be loaded in advance

R is able to check the SHA1 sum of Gists. The PennTURBO team has been using this feature. 

>  Error: SHA-1 hash of downloaded

Indicates may indicate that the gist has been modified since the last modification to `rxnav_med_mapping_solr_upload_post.R`. The user should determine if they trust the modified gist. If so, update the SHA1 argument passed to `source_gist`

TODO: move gist from Mark's personal repo and into a PennTURBO repo.

This script currently requires a properly formatted `turbo_R_setup.yaml` in the home directory of the user who started this script

see https://gist.github.com/turbomam/a3915d00ee55d07510493a9944f96696 for template

TODO: think of a better place to keep  `turbo_R_setup.yaml` , or even make other changes to the config/setup approach



  `turbo_R_setup.yaml` has settings for 

- the GraphDB triplestore form which medication knowledge will be retrieved
- the Solr server and core to which it will be sent, as a Solr-ready JSON file
- ssh and filesystem details, which are used for moving the JSON file to a server from which it can be posted to the Solr server. requires ssh public key (passwordless) login