#!/bin/bash
docker compose exec -T configSrv mongosh --port 27017 <<EOF
rs.initiate({ _id : "config_server", configsvr: true, members: [ { _id : 0, host : "configSrv:27017" } ]});
exit
EOF
sleep 1

docker compose exec -T shard1 mongosh --port 27018 <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard1-1:27019" },
        { _id : 2, host : "shard1-2:27021" },
        { _id : 3, host : "shard1-3:27022" },
      ]
    }
)
exit
EOF
sleep 1

docker compose exec -T shard2 mongosh --port 27023 <<EOF
rs.initiate(
  {
    _id : "shard2",
    members: [
      { _id : 0, host : "shard2:27023" },
      { _id : 1, host : "shard2-1:27024" },
      { _id : 2, host : "shard2-2:27025" },
      { _id : 3, host : "shard2-3:27026" },
    ]
  }
)
exit
EOF
sleep 1

docker compose exec -T mongos_router mongosh --port 27020 <<EOF
sh.addShard("shard1/shard1:27018,shard1-1:27019,shard1-2:27021,shard1-3:27022")
sh.addShard("shard2/shard2:27023,shard2-1:27024,shard2-2:27025,shard2-3:27026")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
exit
EOF