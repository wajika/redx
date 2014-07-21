[![Build Status](https://travis-ci.org/rstudio/redx.svg)](https://travis-ci.org/rstudio/redx)
redx (experimental)
======

Redx (or redis-nginx) is an embedded lua based approach of having a dynamic configuration of nginx of frontends and backends with redis as the data store. Its inspired by [hipache](https://github.com/samalba/hipache-nginx). It has a restful api (that runs within nginx itself) to manage the many-to-one relationships between frontends to backends. 

One of the main benefits of redx is the ability to update your nginx config without needing to reload nginx. This is useful for environments that are nearly constantly changing their large nginx config due to cases such as elastic backends or new user signups. Also, this allows you to have a single nginx config across multiple nginx servers making it easier to have high availability and scalability on your load balancing layer. 

How it works
============

Redx is composed of two components; the api and main. The api is a restful api embedded in lua and runs within the nginx process. It runs on a specific port and is manages the backends associated to references in the redis database.

The other component is main, and this is what takes regular traffic, looks up the proper backend based on host and path.

Setup Dev Environment
=====================

Setup and start vagrant

```bash
  vagrant plugin install vagrant-berkshelf --plugin-version '>= 2.0.1'
  vagrant plugin install vagrant-omnibus
  vagrant up
```

The redx code on your local workstation is run within vagrant (due to sharing the redx directory with vagrant at `/home/vagrant/redx`). As you make code changes, they should take affect immediately and do not require reloading nginx. You will however need to reload nginx when you change the nginx config located `vagrant://etc/nginx/sites-available/redx.conf`.
To see redx logs, see `/var/log/nginx/[access,error].log`

Testing
=======

Redx uses a testing framework, [busted](http://olivinelabs.com/busted/), to run integration tests. To run these tests, execute `busted lua/spec`

API
===

### (GET|POST|PUT|DELETE) /frontends/\<url\>/\<backend_name\>

The `frontends` endpoint allows you to get, update, or delete a frontend. Take note that `POST` and `PUT` are treated the same on this endpoint. It is also important that you character escape the frontend url properly.

#### Examples

##### `GET` example
```
curl localhost:8081/frontends/myhost.com%2Ftest
```

##### `POST/PUT` example
```
curl -X POST localhost:8081/frontends/myhost.com%2Ftest/mybackend
```

##### `DELETE` example
```
curl -X DELETE localhost:8081/frontends/myhost.com%2Ftest
```

### (GET|POST|PUT|DELETE) /backends/\<name\>/\<server\>

The `backends` endpoint allows you to get, update, replace, or delete a backend. Using the `POST` method will "append-only" to the backend, while the `PUT` method will replace what is there in a single redis commit. Be sure to character escape as needed.

#### Examples

##### `GET` example
```
curl localhost:8081/backends/mybackend
```

##### `POST/PUT` example
```
curl -X POST localhost:8081/backends/mybackend/google.com%3A80
```

##### `DELETE` example
```
# will delete the entire backend
curl -X DELETE localhost:8081/backends/mybackend
# will delete one server in the backend
curl -X DELETE localhost:8081/backends/mybackend/google.com%3A80
```

### (DELETE) /flush

Flush clears the redis database of all data. Its literally runs the [`FLUSHDB`](http://redis.io/commands/flushdb) command within redis.

#### Examples

##### `DELETE` example

```
curl -X DELETE localhost:8081/flush
```
### (POST|PUT|DELETE) /batch

Batch allows you to make multiple edits in a single http request and redis commit. You **MUST** have a json body with your http request. Similar to the `backends` endpoint, the `POST` method will "append-only" to the backend, while the `PUT` method will replace what is there in a single redis commit.

The json body must follow this json structure exactly

```
{
    "frontends": [
        {
            "url": "localhost/search",
            "backend_name": "12345"
        },
        {
            "url": "test.com/menlo/park",
            "backend_name": "menlobackend"
        }
    ],
    "backends": [
        {
            "name": "12345",
            "servers": [
                "google.com:80",
                "duckduckgo.com:80"
            ]
        },
        {
            "name": "menlobackend",
            "servers": [
                "menloparkmuseum.org",
                "tesc.edu"
            ]
        }
    ]
}
```

#### Examples

##### `POST/PUT` example
```
curl -X POST localhost:8081/batch -d '{
    "frontends": [
        {
            "url": "localhost/test",
            "backend_name": "12345"
        }
    ],
    "backends": [
        {
            "name": "12345",
            "servers": [
                "google.com:80",
                "duckduckgo.com:80"
            ]
        }
    ]
}'
```
##### `DELETE` example
```
# will delete the frontend and backend
curl -X DELETE localhost:8081/batch -d '{
    "frontends": [
        {
            "url": "localhost/test"
        }
    ],
    "backends": [
        {
            "name": "12345"
        }
    ]
}'

# will delete only one of the servers in the backend
curl -X DELETE localhost:8081/batch -d '{
    "backends": [
        {
            "name": "12345",
            "servers": [
                "google.com:80"
            ]
        }
    ]
}'
```
