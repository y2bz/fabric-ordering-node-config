echo "Starting Orderer CLI Container"
docker-compose -f ./docker/docker-compose-orderer-cli.yaml up -d

echo "Add new orderer TLS to the application channel"
docker exec orderer-cli sh -c 'peer channel fetch config config_block.pb -o orderer.example.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'
docker exec orderer-cli sh -c 'configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json'
docker exec orderer-cli sh -c 'jq ".channel_group.groups.Orderer.values.BatchSize.value.absolute_max_bytes 
+= [$(cat org6consenter.json)]" config.json > modified_config.json'
docker exec orderer-cli sh -c 'configtxlator proto_encode --input config.json --type common.Config --output config.pb'
docker exec orderer-cli sh -c 'configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb'
docker exec orderer-cli sh -c 'configtxlator compute_update --channel_id mychannel --original config.pb --updated modified_config.pb --output config_update.pb'
docker exec orderer-cli sh -c 'configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json'
docker exec orderer-cli sh -c 'echo "{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"mychannel\", \"type\":2}},\"data\":{\"config_update\":"$(cat config_update.json)"}}}" | jq . > config_update_in_envelope.json'
docker exec orderer-cli sh -c 'configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb'
docker exec orderer-cli sh -c 'peer channel update -f config_update_in_envelope.pb -c mychannel -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'



