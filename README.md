Welcome to DataStax Essentials Day!
===================
![icon](http://i.imgur.com/FoIOBlt.png)

In this session, you'll learn all about DataStax Enterprise. It's a mix between presentation and hands-on. This is your reference for the hands-on content. Feel free to bookmark this page for future reference! 

----------


Hands On Setup
-------------

We have a 3 node cluster for you to play with! The cluster is currently running in both **search** and **analytics** mode so you can take advantage of both Spark and Solr on your Cassandra data. 

You'll be given the connection details when the cluster starts.

To SSH into the cluster connect as root using the password provided and the external address of one of the nodes:
```
ssh root@[ipaddress] 
```

NB an external address is the one you use to connect from outside the cluster. The internal address is the one that the machines use to communicate with each other

* Node 0 IP adress - external and internal e.g. 54.218.62.199, 172.31.30.32
* Node 1 IP adress - external and internal e.g. 54.213.132.207, 172.31.24.137
* Node 2 IP adress - external and internal e.g. 54.186.105.135, 172.31.18.211

You should then be able to connect to the management consoles for OpsCenter, Spark and Solr:

* OpsCenter: http://54.218.62.199:8888 (Node 0 external address)
* Spark Master: http://54.213.132.207:7080 (Node 1 external address)
* Solr UI: http://54.218.62.199:8983/solr (Node 0 external address)

OpsCenter and Solr should always start on Node 0, but you may need to check the node where the Spark Master is running. You can easily do this by connecting to one of the nodes via ssh and using the command:
```
dsetool sparkmaster
spark://172.31.24.137:7077
```

In this example the response tells us that the Spark Master is running on internal address 172.31.24.137 - so we need to use the corresponding external address 54.213.132.207 to acccess it from a browser on a client machine.


#### Connecting to the cluster from DevCenter
- Simply add a new connection
- Enter a name for your connection
- Enter any of the external IP's from above as a contact host
- Wait a few seconds for the connection to complete and the keyspace and table details for the database will be displayed

![DevCenter How To](http://i.imgur.com/8zwzmDj.png)


----------


Hands On DSE Cassandra 
-------------------

Cassandra is the brains of DSE. It's an awesome storage engine that handles replication, availability, structuring, and of course, storing the data at lightning speeds. It's important to get yourself acquainted with Cassandra to fully utilize the power of the DSE Stack. 

#### Creating a Keyspace, Table, and Queries 

You can run the following CQL commands in DevCenter or you can use **cqlsh** as an interactive command line tool for CQL access to Cassandra. 

Start cqlsh like this from the command prompt on one of the nodes in the cluster:

```
cqlsh <private ip address>
``` 
or
```
cqlsh <node name>
```

Let's make our first Cassandra Keyspace! 

```
CREATE KEYSPACE <Enter your name> WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3 };
```

And just like that, any data within any table you create under your keyspace will automatically be replicated 3 times.

> **Hint** - SimpleStrategy is OK for a cluster using a single data center, but in the real world with multiple datacenters you would use the ```NetworkTopologyStrategy``` replication strategy. In fact, even if you start out on your development path with just a single data center, if theres even a chance that you might go to multiple data centers in the future then you should use NetworkTopologyStrategy from the outset.

Let's keep going and create ourselves a table.


```
CREATE TABLE <yourkeyspace>.sales (
	name text,
	time int,
	item text,
	price double,
	PRIMARY KEY (name, time)
) WITH CLUSTERING ORDER BY ( time DESC );
```

> Yup. This table is very simple but don't worry, we'll play with some more interesting tables in just a minute.

Let's get some data into your table! Cut and paste these inserts into DevCenter or CQLSH. Feel free to insert your own data values, as well. 

```
INSERT INTO <yourkeyspace>.sales (name, time, item, price) VALUES ('kunal', 20150205, 'Apple Watch', 299.00);
INSERT INTO <yourkeyspace>.sales (name, time, item, price) VALUES ('kunal', 20150204, 'Apple iPad', 999.00);
INSERT INTO <yourkeyspace>.sales (name, time, item, price) VALUES ('rich', 20150206, 'Music Man Stingray Bass', 1499.00);
INSERT INTO <yourkeyspace>.sales (name, time, item, price) VALUES ('kunal', 20150207, 'Jimi Hendrix Stratocaster', 899.00);
INSERT INTO <yourkeyspace>.sales (name, time, item, price) VALUES ('rich', 20150208, 'Santa Cruz Tallboy 29er', 4599.00);
```

At the moment we're prefixing the keyspace name to the table name in our CQL commands e.g. ```<yourkeyspace>.sales```.

Let's make it a little easier - we can set our ***default*** keyspace so that we dont need to type it every time.

```
use <yourkeyspace>;
```
You can check the tables that are in that keyspace like this:
```
describe tables
```
> Of course, if there are tables with the same name in different keyspaces it may be wiser to continue to use a keyspace prefix to avoid inadvertently modifying the data in the wrong table!

We can check how many rows there are in our table after the insert of five rows:
```
select count(*) from sales;
```

> Be careful with ```count(*)``` - it will scan the entire cluster. This wouldnt be a good idea in a big cluster with millions or billions of rows!

To retrieve data:

```
SELECT * FROM sales where name='kunal' AND time >=20150207 ;
```
>See what I did there? You can do range scans on clustering keys! Give it a try.

----------


Hands On Cassandra Primary Keys 
-------------------

#### The secret sauce of the Cassandra data model: Primary Key

There are just a few key concepts you need to know when beginning to data model in Cassandra. But if you want to know the real secret sauce to solving your use cases and getting great performance, then you need to understand how Primary Keys work in Cassandra. 

Let's dive in! 

Since Cassandra use cases are typically focused on performance and up-time, it's critical to understand how Primary Key (PK) definition, query capabilities, and performance are related.

Here's how to do the exercise...

1) Use the CQL script below to create the tables. You'll notice that all the tables are exactly the same except for the primary key definition.
```
create keyspace if not exists primary_keys_ks with replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };

use primary_keys_ks;

create table sentiment1 (
body text,         // social message body text
dt int,            // date of message
ch text,           // social channel
cu text,           // customer
sent text,         // sentiment indicator
primary key (dt)
);

create table sentiment2 (
body text,
dt int,
ch text,
cu text,
sent text,
primary key ((ch,dt))
);

create table sentiment3 (
body text,
dt int,
ch text,
cu text,
sent text,
primary key (ch,dt)
);

create table sentiment4 (
body text,
dt int,
ch text,
cu text,
sent text,
primary key (ch,cu,dt)
);

create table sentiment5 (
body text,
dt int,
ch text,
cu text,
sent text,
primary key ((ch,dt),cu)
);

```

2) Use the CQL script below to populate the tables with data.
```
begin batch
insert into sentiment1 (body,dt,ch,cu,sent) values ('I''m feeling sick.',20160102,'twitter','red bull','negative');
insert into sentiment2 (body,dt,ch,cu,sent) values ('I''m feeling sick.',20160102,'twitter','red bull','negative');
insert into sentiment3 (body,dt,ch,cu,sent) values ('I''m feeling sick.',20160102,'twitter','red bull','negative');
insert into sentiment4 (body,dt,ch,cu,sent) values ('I''m feeling sick.',20160102,'twitter','red bull','negative');
insert into sentiment5 (body,dt,ch,cu,sent) values ('I''m feeling sick.',20160102,'twitter','red bull','negative');
apply batch;

begin batch
insert into sentiment1 (body,dt,ch,cu,sent) values ('That was sick!',20160101,'facebook','red bull','positive');
insert into sentiment2 (body,dt,ch,cu,sent) values ('That was sick!',20160101,'facebook','red bull','positive');
insert into sentiment3 (body,dt,ch,cu,sent) values ('That was sick!',20160101,'facebook','red bull','positive');
insert into sentiment4 (body,dt,ch,cu,sent) values ('That was sick!',20160101,'facebook','red bull','positive');
insert into sentiment5 (body,dt,ch,cu,sent) values ('That was sick!',20160101,'facebook','red bull','positive');
apply batch;

begin batch
insert into sentiment1 (body,dt,ch,cu,sent) values ('I feel sick, too.',20160102,'facebook','dew tour','negative');
insert into sentiment2 (body,dt,ch,cu,sent) values ('I feel sick, too.',20160102,'facebook','dew tour','negative');
insert into sentiment3 (body,dt,ch,cu,sent) values ('I feel sick, too.',20160102,'facebook','dew tour','negative');
insert into sentiment4 (body,dt,ch,cu,sent) values ('I feel sick, too.',20160102,'facebook','dew tour','negative');
insert into sentiment5 (body,dt,ch,cu,sent) values ('I feel sick, too.',20160102,'facebook','dew tour','negative');
apply batch;

begin batch
insert into sentiment1 (body,dt,ch,cu,sent) values ('Dude, you''re sick.',20160103,'facebook','red bull','positive');
insert into sentiment2 (body,dt,ch,cu,sent) values ('Dude, you''re sick.',20160103,'facebook','red bull','positive');
insert into sentiment3 (body,dt,ch,cu,sent) values ('Dude, you''re sick.',20160103,'facebook','red bull','positive');
insert into sentiment4 (body,dt,ch,cu,sent) values ('Dude, you''re sick.',20160103,'facebook','red bull','positive');
insert into sentiment5 (body,dt,ch,cu,sent) values ('Dude, you''re sick.',20160103,'facebook','red bull','positive');
apply batch;

begin batch
insert into sentiment1 (body,dt,ch,cu,sent) values ('How sick was that?',20160103,'facebook','monster energy','positive');
insert into sentiment2 (body,dt,ch,cu,sent) values ('How sick was that?',20160103,'facebook','monster energy','positive');
insert into sentiment3 (body,dt,ch,cu,sent) values ('How sick was that?',20160103,'facebook','monster energy','positive');
insert into sentiment4 (body,dt,ch,cu,sent) values ('How sick was that?',20160103,'facebook','monster energy','positive');
insert into sentiment5 (body,dt,ch,cu,sent) values ('How sick was that?',20160103,'facebook','monster energy','positive');
apply batch;
```

3) Look at these queries. For one table at a time, copy/paste/run the groups of queries. In other words, run all of the queries for sentiment1 at the same time. Check out Cassandra's response. Then run all queries for sentiment2 at the same time, etc. You'll notice that some of the queries work against some of the tables, but not all. Why?
```
select * from sentiment1 where dt = 20160102;
select * from sentiment1 where ch = 'facebook' and dt = 20160102;
select * from sentiment1 where ch = 'facebook' and dt > 20160101;

select * from sentiment2 where dt = 20160102;
select * from sentiment2 where ch = 'facebook' and dt = 20160102;
select * from sentiment2 where ch = 'facebook' and dt > 20160101;

select * from sentiment3 where dt = 20160102;
select * from sentiment3 where ch = 'facebook' and dt = 20160102;
select * from sentiment3 where ch = 'facebook' and dt > 20160101;
select * from sentiment3 where ch = 'facebook' and cu = 'red bull' and dt >= 20160102 and dt <= 20160103;
select * from sentiment3 where ch = 'facebook' and dt >= 20160102 and dt <= 20160103;

select * from sentiment4 where dt = 20160102;
select * from sentiment4 where ch = 'facebook' and cu = 'red bull' and dt >= 20160102 and dt <= 20160103;
select * from sentiment4 where ch = 'facebook' and dt >= 20160102 and dt <= 20160103;

select * from sentiment5 where dt = 20160102;
select * from sentiment5 where ch = 'facebook' and dt = 20160102;
select * from sentiment5 where ch = 'facebook' and dt > 20160101;
select * from sentiment5 where ch = 'facebook' and dt >= 20160102 and dt <= 20160103;
```

4) Extra Credit 1: Did the query "select * from sentimentX where ch = 'facebook' and dt >= 20160102 and dt <= 20160103;" work for any of the tables? Why or why not?

5) Extra Credit 2: What would you do if you needed to find all messages with positive sentiment?

6) Challenge Question: In the real world, how many tweets would you guess occur per day? As of this writing, Twitter generates ~500M tweets/day according to [these guys](http://www.internetlivestats.com/twitter-statistics/). Let's say we need to run a query that captures all tweets over a specified range of time. Given our data model scenario, we simply data model a primary key value of (ch, dt) to capture all tweets in a single Cassandra row sorted in order of time, right? Easy! But, alas, the Cassandra logical limit of single row size (2B columns in C* v2.1) would fill up after about 4 days! Our primary key won't work. What would we do to solve our query?

Have fun!

Cassandra Data Model and Query Pro-Tips
---------------------------------------

Here are a few Cassandra data modeling pro-tips and principles to stay out of trouble and get you moving the right direction:

**Primary Keys**: Know what a partition key is. Know what a clustering key is. Know how they work for storing the data and for allowing query functionality. This exercise is a great start.

**Secondary Indexes**: If you're tempted to use a secondary index in Cassandra in production, at least in Cassandra 2.1, don't do it. Instead, create a new table with a PK definition that will meet your query needs. In Cassandra, denormalization is fast and scalable. Secondary indexes aren't as much. Why? Lots of reason that have to do with the fact that Cassandra is a distributed system. It's a good thing.

**Relational Data Models**: Relational data models don't work well (or at all) in Cassandra. That's a good thing, because Cassandra avoids the extra overhead involved in processing relational operations. It's part of what makes Cassandra fast and scalable. It also means you should not copy your relational tables to Cassandra if you're migrating a relational system to Cassandra. Use a well-designed Cassandra data model.

**Joins**: Cassandra doesn't support joins. How do you create M:1 and M:M relations? Easy... denormalize your data model and use a PK definition that works. Think in materialized views. Denormalization is often a no-no in relational systems. To get 100% up-time, massive scale/throughput and speed that Cassandra delivers, it's the right way to go.

**Allow Filtering**: If you're tempted to use Allow Filtering in production, see the advice for Secondary Indexes above.

**Batche**s: Batches solve a different problem in Cassandra than they do in relational databases. Use them to get an atomic operation for a single PK across multiple tables. Do NOT use them to batch large numbers of operations assuming Cassandra will optimize the query performance of the batch. It doesn't work that way. Use batches appropriately or not at all.


----------


Hands On Cassandra Consistency 
-------------------

#### Let's play with consistency!

Consistency in Cassandra refers to the number of acknowledgements that replica nodes need to send to the coordinator for an operation to be considered successful whilst also providing good data (avoiding dirty reads). 

We recommend a ** default replication factor of 3 and consistency level of LOCAL_QUORUM as a starting point**. You will almost always get the performance you need with these default settings.

In some cases, developers find Cassandra's replication fast enough to warrant lower consistency for even better latency SLA's. For cases where very strong global consistency is required, possibly across data centers in real time, a developer can trade latency for a higher consistency level. 

Let's give it a shot. 

>During this exercise, I'll be taking down nodes so you can see the CAP theorem in action. We'll be using CQLSH for this one. 

**In CQLSH**:

```
tracing on
consistency all
```

Any query will now be traced. Cassandra provides a description of each step it takes to satisfy the request, the names of nodes that are affected, the time for each step, and the total time for the request.

**Consistency** level "all" means all 3 replicas need to respond to a given request (read OR write) to be successful. Let's do a **SELECT** statement to see the effects.

Set your keyspace created earlier as the default keyspace:
```
use <yourkeyspace>;
```
Retrieve all rows where name="kunal":
```
SELECT * FROM sales where name='kunal';
```

How did we do? We returned three records. Total elapsed time for the request on our 3-node cluster was 16370 microseconds. 

```
Request complete | 2016-06-02 08:13:54.028370 |  172.31.30.32 |          16370
```

**Let's compare a lower consistency level:**

```consistency local_quorum```
>Quorum means majority: RF/2 + 1. In our case, 3/2 = 1 + 1 = 2. At least 2 nodes need to acknowledge the request. 

Let's try the **SELECT** statement again. Any changes in latency? 

>Keep in mind that our dataset is so small, it's sitting in memory on all nodes. With larger datasets that spill to disk, the latency cost become much more drastic.

```
Request complete | 2016-06-02 08:17:55.348393 |  172.31.30.32 |           4393
```

This looks much better now doesn't it? **LOCAL_QUORUM** is the most commonly used consistency level among developers. It provides a good level of performance and a moderate amount of consistency. That being said, many use cases can warrant  **CL=LOCAL_ONE**. 

For more detailed classed on data modeling, consistency, and Cassandra 101, check out the free classes at the [DataStax Academy](www.academy.datastax.com) website. 

----------


Hands On DSE Search
-------------
DSE Search is awesome. You can configure which columns of which Cassandra tables you'd like indexed in **lucene** format to make extended searches more efficient whilst enabling features such as text search and geospatial search. 

Let's start off by indexing the tables we've already made. Here's where the dsetool really comes in handy:

```
dsetool create_core <yourkeyspace>.sales generateResources=true reindex=true
```

>If you've ever created your own Solr cluster, you know you need to create the core and upload a schema and config.xml. That **generateResources** tag does that for you. For production use, you'll want to take the resources and edit them to your needs but it does save you a few steps. 

This by default will map Cassandra types to Solr types for you. Anyone familiar with Solr knows that there's a REST API for querying data. In DSE Search, we embed that into CQL so you can take advantage of all the goodness CQL brings. Let's give it a shot. 

Run the following commands in cqlsh:
```
select * from sales WHERE solr_query='{"q":"name: kunal"}';
```

Output should be like this:
```
 name  | time     | item                      | price | solr_query
-------+----------+---------------------------+-------+------------
 kunal | 20150207 | Jimi Hendrix Stratocaster |   899 |       null
 kunal | 20150205 |               Apple Watch |   299 |       null
 kunal | 20150204 |                Apple iPad |   999 |       null
```

Let's try a filter query to return only the items from Apple: 
```
select * from sales WHERE solr_query='{"q":"name:kunal", "fq":"item:*pple*"}'; 

 name  | time     | item        | price | solr_query
-------+----------+-------------+-------+------------
 kunal | 20150205 | Apple Watch |   299 |       null
 kunal | 20150204 |  Apple iPad |   999 |       null
```

We can control how the data is sorted based on a column value:
```
select * from sales WHERE solr_query='{"q":"name:kunal", "fq":"item:*pple*", "sort":"price desc"}';

 name  | time     | item        | price | solr_query
-------+----------+-------------+-------+------------
 kunal | 20150204 |  Apple iPad |   999 |       null
 kunal | 20150205 | Apple Watch |   299 |       null
 ```
 
> For your reference, [here's the doc](http://docs.datastax.com/en/datastax_enterprise/4.8/datastax_enterprise/srch/srchCql.html?scroll=srchCQL__srchSolrTokenExp) that shows some of things you can do.

OK! Time to work with some more interesting data. Meet Amazon book sales data.

1. Install pip:
```
sudo apt-get install gcc python-dev
sudo apt-get install python-pip python-dev build-essential 
sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv 
```
2. Install the Python Cassandra Driver (note - this might take some time on smaller machines):
```
sudo pip install cassandra-driver
``` 
3. Run solr_dataloader.py
  * This will create the CQL schemas and load the data 
4. Run create_core.sh 
  * This will generate Solr cores and index the data


The Amazon data model includes the following tables:


Click stream data:
```
CREATE TABLE amazon.clicks (
    asin text,
    seq timeuuid,
    user uuid,
    area_code text,
    city text,
    country text,
    ip text,
    loc_id text,
    location text,
    location_0_coordinate double,
    location_1_coordinate double,
    metro_code text,
    postal_code text,
    region text,
    solr_query text,
    PRIMARY KEY (asin, seq, user)
) WITH CLUSTERING ORDER BY (seq DESC, user ASC);
```
And book metadata: 

```
CREATE TABLE amazon.metadata (
    asin text PRIMARY KEY,
    also_bought set<text>,
    buy_after_viewing set<text>,
    categories set<text>,
    imurl text,
    price double,
    solr_query text,
    title text
);
```

So what are things you can do? 

*Filter queries*: These are awesome because the result set gets cached in memory. 
```
SELECT * FROM amazon.metadata WHERE solr_query='{"q":"title:Noir~", "fq":"categories:Books", "sort":"title asc"}' limit 10; 
```
*Faceting*: Get counts of fields 

```
SELECT * FROM amazon.metadata WHERE solr_query='{"q":"title:Noir~", "facet":{"field":"categories"}}' limit 10; 
```
*Geospatial Searches*: Supports box and radius
```
SELECT * FROM amazon.clicks WHERE solr_query='{"q":"asin:*", "fq":"+{!geofilt pt=\"37.7484,-122.4156\" sfield=location d=1}"}' limit 10; 
```
*Joins*: Not your relational joins. These queries 'borrow' indexes from other tables to add filter logic. These are fast! 
```
SELECT * FROM amazon.metadata WHERE solr_query='{"q":"*:*", "fq":"{!join from=asin to=asin force=true fromIndex=amazon.clicks}area_code:415"}' limit 5; 
```
*Fun all in one* 
```
SELECT * FROM amazon.metadata WHERE solr_query='{"q":"*:*", "facet":{"field":"categories"}, "fq":"{!join from=asin to=asin force=true fromIndex=amazon.clicks}area_code:415"}' limit 5;
```
> Check this example page of what's in the DB http://www.amazon.com/Science-Closer-Look-Grade-6/dp/0022841393/ref=sr_1_1?ie=UTF8&qid=1454964627&sr=8-1&keywords=0022841393

Want to see a really cool example of a live DSE Search app? Check out [KillrVideo](http://www.killrvideo.com/) and its [Git](https://github.com/luketillman/killrvideo-csharp) to see it in action. 

----------


Hands On DSE Analytics
--------------------

Spark is general cluster compute engine. You can think of it in two pieces: **Streaming** and **Batch**. **Streaming** is the processing of incoming data (in micro batches) before it gets written to Cassandra (or any database). **Batch** includes both data crunching code and **SparkSQL**, a hive compliant SQL abstraction for **Batch** jobs. 

It's a little tricky to have an entire class run streaming operations on a single cluster, so if you're interested in dissecting a full scale streaming app, check out [THIS git](https://github.com/retroryan/SparkAtScale).  

>Spark has a REPL we can play in. To make things easy, we'll use the SQL REPL:

```dse spark-sql --conf spark.ui.port=<Pick a random 4 digit number> --conf spark.cores.max=1```

>Notice the spark.ui.port flag - Because we are on a shared cluster, we need to specify a radom port so we don't clash with other users. We're also setting max cores = 1 or else one job will hog all the resources. 

Try some CQL commands

```use <your keyspace>;```
```SELECT * FROM <your table> WHERE...;```

And something not too familiar in CQL...
```SELECT sum(price) FROM <your table>...;```

Let's try having some fun on that Amazon data:

```
SELECT sum(price) FROM metadata;
```
```
SELECT m.title, c.city FROM metadata m JOIN clicks c ON m.asin=c.asin;
```
```
SELECT asin, sum(price) AS max_price FROM metadata GROUP BY asin ORDER BY max_price DESC limit 1;
```
----------


DSE Streaming Demo
--------------------
**Spark Notebook**

[Spark Notebook](http://spark-notebook.io/) is an awesome tool for exploring Spark and making simple visualizations. It's not a DataStax product. Check in back here again soon for a quick demo. See: https://github.com/retroryan/twitter_classifier/tree/master/notebooks/TweetAnalysis

>Have fun with it! See what you come up with :)

----------


Getting Started With DSE Ops
--------------------

Most of us love to have tools to monitor and automate database operations. For Cassandra, that tool is DataStax OpsCenter. If you prefer to roll with the command line, then two core utilities you'll need to understand are nodetool and dsetool.

**Utilities you'll want to know:**
```
nodetool  //Cassandra's main utility tool
dsetool   //DSE's main utility tool
```
**nodetool Examples:**
```
nodetool status  //shows current status of the cluster 

nodetool tpstats //shows thread pool status - critical for ops
```

**dsetool Examples:**
```
dsetool status //shows current status of cluster, including DSE features

dsetool create_core //will create a Solr schema on Cassandra data for Search
```

**The main log you'll be taking a look at for troubleshooting outside of OpsCenter:**
```
/var/log/cassandra/system.log
```

