# Sporran - a PouchDB alike database client for Dart

## Introduction

This is a Dart CouchDB client imitating [PouchDB](http://pouchdb.com/). The client can operate either online or offline, synching database changes between the two whenever the user's connectivity changes. 

This is a fork of [Sporran](https://github.com/shamblett/sporran), which originally ony allowed browser-based clients using dart:html. This fork adds functionality for server-side clients using dart:io. In-memory databases are used for local replication in both cases. This can also be extended.

However, this fork has introduced a lot of breaking changes. Eventually, I'll rename it (while still giving credit to Steve Hamblett, the original author of Sporran). This fork also is not yet officially released, so there's no guarantee that the master branch will even compile at any given time. This also relies on a [fork](https://github.com/nmfisher/wilt) of [Steve Hamblett's Wilt](https://github.com/shamblett/wilt) which will need to be rationalized at some point.

When the browser is online Sporran acts just like Wilt, i.e is a CouchDB client, but all database
transactions are reflected into local storage. 

If the browser goes offline Sporran switches to using local storage only, when the browser comes back 
online the local database is synced up with CouchDB, all transparent to the user.

The CouchDB change notification interface is also used to keep Sporran in sync with any 3rd party
changes to your CouchDB database.

Please read the documents under the doc folder for usage information, the API is also under
this folder and is available [here](http://oscf.org.uk/dart/api/sporran)

## Issues

Please raise an issue if you have a feature request or have encountered a bug.
PRs are welcome.


