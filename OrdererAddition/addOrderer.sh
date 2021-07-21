echo "Starting Orderer CLI Container"
docker-compose -f ./docker/docker-compose-orderer-cli.yaml up -d

echo "Adding new orderer TLS to the system channel (system-channel)"
 ./OrdererAddition/addTLSsys-channel.sh

echo "Fetch the latest configuration block"
./OrdererAddition/fetchConfigBlock.sh

echo "Bring Orderer4 Container"
docker-compose -f ./docker/docker-compose-orderer.yaml up -d

echo "Adding new Orderer endpoint to the system channel (mychannel)"
./OrdererAddition/addEndPointSys-channel.sh

echo "System channel Size"
docker exec orderer.example.com ls -lh /var/hyperledger/production/orderer/chains/system-channel
docker exec orderer4.example.com ls -lh /var/hyperledger/production/orderer/chains/system-channel

echo "Add new orderer TLS to the application channel"
./OrdererAddition/addTLSapplication-channel.sh

echo "Adding new Orderer endpoint to the application channel (mychannel)"
./OrdererAddition/addEndPointapplication-channel.sh


echo "Application channel Size (after channel update)"
docker exec orderer.example.com ls -lh /var/hyperledger/production/orderer/chains/mychannel
docker exec orderer4.example.com ls -lh /var/hyperledger/production/orderer/chains/mychannel
