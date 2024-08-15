#!/bin/bash

# Check if docker is installed and ask to download and install it if not.
if [ ! -x "$(command -v docker)" ]; then
        read -p "Docker is not installed, would you like to install it? (y/n) [y]: " downloaddocker
        downloaddocker=${downloaddocker:-y}
        echo $downloaddocker

        if [[ "$downloaddocker" == "y" ]]; then
                echo "Installing docker... you may need to enter your password for the 'sudo' command"
                sudo apt-get update && sudo apt-get install ca-certificates curl && sudo install -m 0755 -d /etc/apt/keyrings && sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && sudo chmod a+r /etc/apt/keyrings/docker.asc && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                echo "Docker installation done!"
        fi
fi

# Download .env, default.conf, and compose.yaml if they do not exist. Ask if they should be downloaded
if [ ! -f compose.yaml ]; then
        read -p "The compose.yaml file does not exist, would you like to download it? (y/n) [y]: " downloadcompose
        downloadcompose=${downloadcompose:-y}
        echo $downloadcompose

        if [[ "$downloadcompose" == "y" ]]; then
                echo "Downloading compose.yaml..."
                curl -O https://raw.githubusercontent.com/Ne0n09/cloudflared-remotefalcon/main/compose.yaml
                echo "Done."
        fi
fi

if [ ! -f default.conf ]; then
        read -p "The nginx default.conf file does not exist, would you like to download it? (y/n) [y]: " downloadnginxconf
        downloadnginxconf=${downloadnginxconf:-y}
        echo $downloadnginxconf

        if [[ "$downloadnginxconf" == "y" ]]; then
                echo "Downloading default.conf..."
                curl -O https://raw.githubusercontent.com/Ne0n09/cloudflared-remotefalcon/main/default.conf
                echo "Done."
        fi
fi

# Print existing .env file variables, if it exists
if [ -f .env ]; then
        echo "Source .env exists!"
        echo "Printing current values:"
        echo
        cat .env
        echo
        # Load the existing .env variables to allow for auto-completion
        source .env
else
        echo "Source .env DOES not exist!"
        echo "Setting some default values..."
        VIEWER_JWT_KEY="123456"
        HOSTNAME_PARTS="2"
        AUTO_VALIDATE_EMAIL="true"
fi

echo "Answer the following questions to update your compose .env variables."
echo "Press enter to accept the existing values that are between the brackets [ ]."
echo "You will be asked to confirm the changes before the file is modified."

read -p "Enter your Cloudflare tunnel token: [$TUNNEL_TOKEN]: " tunneltoken
tunneltoken=${tunneltoken:-$TUNNEL_TOKEN}

read -p "Enter your domain name, example: yourdomain.com: [$DOMAIN]: " domain
domain=${domain:-$DOMAIN}

read -p "Enter a random value for viewer JWT key: [$VIEWER_JWT_KEY]: " viewerjwtkey
viewerjwtkey=${viewerjwtkey:-$VIEWER_JWT_KEY}

read -p "Enter the number of parts in your hostname. For example, domain.com would be two parts ('domain' and 'com'), and sub.domain.com would be 3 parts ('sub', 'domain', and 'com'): [$HOSTNAME_PARTS]: " hostnameparts
hostnameparts=${hostnameparts:-$HOSTNAME_PARTS}

read -p "Enable auto validate email? (true/false): [$AUTO_VALIDATE_EMAIL]: " autovalidateemail
autovalidateemail=${autovalidateemail:-$AUTO_VALIDATE_EMAIL}

read -p "Update origin certificates? (y/n) [n]: " updatecerts
updatecerts=${updatecerts:-n}
echo $updatecerts
if [[ "$updatecerts" == "y" ]]; then
        read -p "Press any key to open nano to paste the origin certificate. Ctrl+X and y to save."
        nano origin_cert.pem

        read -p "Press any key to open nano to paste the origin private key. Ctrl+X and y to save."
        nano origin_key.pem
fi

echo
echo "Please confirm the new variables below are correct:"
echo "TUNNEL_TOKEN=$tunneltoken"
echo "DOMAIN=$domain"
echo "VIEWER_JWT_KEY=$viewerjwtkey"
echo "HOSTNAME_PARTS=$hostnameparts"
echo "AUTO_VALIDATE_EMAIL=$autovalidateemail"

read -p "Update the .env file with the above variables? (y/n): " updateenv

if [[ "$updateenv" == "y" ]]; then
        echo "Writing variables to .env file..."
        echo "Writing TUNNEL_TOKEN=$tunneltoken"
        echo "TUNNEL_TOKEN=$tunneltoken" > .env
        echo "Writing DOMAIN=$domain"
        echo "DOMAIN=$domain" >> .env
        echo "Writing VIEWER_JWT_KEY=$viewerjwtkey"
        echo "VIEWER_JWT_KEY=$viewerjwtkey" >> .env
        echo "Writing HOSTNAME_PARTS=$hostnameparts"
        echo "HOSTNAME_PARTS=$hostnameparts" >> .env
        echo "Writing AUTO_VALIDATE_EMAIL=$autovalidateemail"
        echo "AUTO_VALIDATE_EMAIL=$autovalidateemail" >> .env
        echo "NGINX_CONF=./default.conf" >> .env
        echo "NGINX_CERT=./origin_cert.pem" >> .env
        echo "NGINX_KEY=./origin_key.pem" >> .env
        echo "Done!"
        echo "If the containers were already running you will need to run 'docker compose down' and 'docker compose up -d' for the new values to take effect."

        read -p "Would you like to do this now? (y/n): " restart
        echo $restart
        if [[ "$restart" == "y" ]]; then
                echo "You may be asked to Eenter your password to run 'sudo' commands"
                echo "sudo docker compose down"
                sudo docker compose down
                echo "sudo docker compose up -d"
                sudo docker compose up -d
                echo "Sleeping 5 seconds before running 'sudo docker ps'"
                sleep 5s
                echo "sudo docker ps"
                sudo docker ps
                echo "Done. Verify that all containers show 'Up'"
        fi
else
        echo "Variables were not updated! No changes were made to the .env file"
fi
