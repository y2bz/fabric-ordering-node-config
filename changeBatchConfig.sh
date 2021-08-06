echo "set absolute_max_bytes:$1"
echo "set max_message_count:$2"
echo "set preferred_max_bytes:$3"
echo "set batchTimeout:$4"

echo "Starting Orderer CLI Container"
docker-compose -f ./docker/docker-compose-orderer-cli.yaml up -d

echo "Put new config into the application channel"
docker exec orderer-cli sh -c 'peer channel fetch config config_block.pb -o orderer.example.com:7050 -c system-channel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'
docker exec orderer-cli sh -c 'configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json'
docker exec orderer-cli sh -c "jq '.channel_group.groups.Orderer.values.BatchSize.value.absolute_max_bytes = $1' config.json > config1.json"
docker exec orderer-cli sh -c "jq '.channel_group.groups.Orderer.values.BatchSize.value.max_message_count = $2' config1.json > config2.json"
docker exec orderer-cli sh -c "jq '.channel_group.groups.Orderer.values.BatchSize.value.preferred_max_bytes = $3' config2.json > config3.json"
docker exec orderer-cli sh -c "jq '.channel_group.groups.Orderer.values.BatchTimeout.value.timeout = \"$4\"' config3.json > modified_config.json"
docker exec orderer-cli sh -c 'configtxlator proto_encode --input config.json --type common.Config --output config.pb'
docker exec orderer-cli sh -c 'configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb'
docker exec orderer-cli sh -c 'configtxlator compute_update --channel_id system-channel --original config.pb --updated modified_config.pb --output config_update.pb'
docker exec orderer-cli sh -c 'configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json'
docker exec orderer-cli sh -c 'echo "{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"system-channel\", \"type\":2}},\"data\":{\"config_update\":"$(cat config_update.json)"}}}" | jq . > config_update_in_envelope.json'
docker exec orderer-cli sh -c 'configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb'
docker exec orderer-cli sh -c 'peer channel update -f config_update_in_envelope.pb -c system-channel -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'

echo "Check out the new config"
docker exec orderer-cli sh -c 'peer channel fetch config config_block.pb -o orderer.example.com:7050 -c system-channel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'
docker exec orderer-cli sh -c 'configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config.channel_group.groups.Orderer.values > ordererValue.json'
docker cp orderer-cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/ordererValue.json ./check_ordererValue.json

echo "Shutdown Orderer CLI Container"
docker-compose -f ./docker/docker-compose-orderer-cli.yaml down -d


