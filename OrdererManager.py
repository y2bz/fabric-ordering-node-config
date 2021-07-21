import os
import random
import json

jsonfile = './ordererInfo.json'

with open(jsonfile) as f:
    orderer_info = json.load(f)

orderer1 = ["orderer", 5051]
active_orderers = orderer_info['active_orderers']
inactive_orderers = orderer_info['inactive_orderers']

def pick_one(orderer_list):
    random_index = random.randint(0, len(orderer_list)-1)
    return orderer_list.pop(random_index)

def generate_add_config(orderer_name, assigned_port):
    new_config = ''
    with open('./docker/docker-compose-orderer-template.yaml', "r", encoding="utf-8") as f:
        for line in f:
            if '_orderer_' in line:
                line = line.replace('_orderer_', orderer_name)
            if '_port_' in line:
                line = line.replace('_port_', str(assigned_port))
            new_config += line
    with open('./docker/docker-compose-orderer.yaml',"w",encoding="utf-8") as f:
        f.write(new_config)

def generate_del_config(orderer_name, assigned_port):
    new_config = ''
    with open('./docker/docker-compose-del-orderer-template.yaml', "r", encoding="utf-8") as f:
        for line in f:
            if '_orderer_' in line:
                line = line.replace('_orderer_', orderer_name)
            if '_port_' in line:
                line = line.replace('_port_', str(assigned_port))
            new_config += line
    with open('./docker/docker-compose-del-orderer.yaml',"w",encoding="utf-8") as f:
        f.write(new_config)

def del_orderer(orderer):
    generate_del_config(orderer[0], orderer[1])
    os.system('./delOneOrderer.sh ' + orderer[0])
    print('----------成功删除' + orderer[0] + '----------')

def add_orderer(orderer):
    generate_add_config(orderer[0], orderer[1])
    os.system('./addOneOrderer.sh ' + orderer[0])
    print('----------成功加入' + orderer[0] + '----------')

def update_orderers():
    del_list = []
    for i in range(2):
        del_list.append(pick_one(active_orderers))
    for orderer in del_list:
        del_orderer(orderer)
    add_list = []
    for i in range(2):
        add_list.append(pick_one(inactive_orderers))
    for orderer in add_list:
        add_orderer(orderer)
    active_orderers.extend(add_list)
    inactive_orderers.extend(del_list)
    save_data = { "active_orderers": active_orderers, "inactive_orderers": inactive_orderers }
    with open(jsonfile, "w") as f:
        json.dump(save_data, f)
    active_orderers.append(orderer1)
    print('参与排序：', active_orderers)
    print('未参与排序：', inactive_orderers)

os.system('./startcli.sh')
update_orderers()
