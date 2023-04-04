generate-files:
	mkdir -p ./artifacts/config
	docker compose run \
	 -e CONFIG="agent.bu" \
	 -e OUTPUT_NAME="agent1" \
	 -e ENVS="./envs/common.env,./envs/agents/agent-common.env,./envs/agents/agent-1-x86_64.env" \
	 config-builder

generate-files:
	mkdir -p ./artifacts/isos
	docker compose run \
	 -e CONFIG="agent.bu" \
	 -e OUTPUT_NAME="agent1" \
	 -e ENVS="./envs/common.env,./envs/agents/agent-common.env,./envs/agents/agent-1-x86_64.env" \
	 config-builder
	docker compose run \
	 -e CONFIG="server.bu" \
	 -e OUTPUT_NAME="server" \
	 -e ENVS="./envs/common.env,./envs/server/server.env" \
	 config-builder

create-isos:
	docker compose run \
		-e DEVICE="/dev/sda" \
		-e IGNITION="/config/server.ign" \
		-e ISO="server.iso" \
		 iso-builder
	docker compose run \
		-e DEVICE="/dev/nvme0n1" \
		-e IGNITION="/config/agent1.ign" \
		-e ISO="agent1.iso" \
		 iso-builder
