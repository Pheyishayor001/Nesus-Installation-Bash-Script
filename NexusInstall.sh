#!/bin/bash 

echo "Updating system packages"
sudo yum update -y || { echo "Failed to update packages"; exit 1; }     

echo "Installing Java"
# sudo yum install java-1.8.0-openjdk -y || { echo "Failed to install Java"; exit 1; }
wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz
if command -v java &> /dev/null; then
    echo "Java is already installed. Skipping download and setup."      
else
    echo "Java is not installed. Proceeding with download and setup."   

    # Download Java
    sudo yum install java-1.8.0-openjdk -y || { echo "Failed to install Java"; exit 1; }

    echo "Java installation completed."
fi

echo "Verifying Java installation"
java -version || { echo "Java installation verification failed"; exit 1; }

# Define the Nexus version and installation path
NEXUS_VERSION="nexus-3.45.0-01"
NEXUS_DIR="/opt/nexus"
NEXUS_TAR="${NEXUS_VERSION}-unix.tar.gz"

# Check if Nexus is already installed
if [ -d "$NEXUS_DIR" ]; then
    echo "Nexus is already installed. Skipping download and setup."     
else
    echo "Nexus is not installed. Proceeding with download and setup."  

    # Download Nexus
    echo "Downloading Nexus"
    sudo wget https://download.sonatype.com/nexus/3/nexus-3.45.0-01-unix.tar.gz || { echo "Failed to download Nexus"; exit 1; }

    # Update system packages
    echo "Updating system packages again"
    sudo yum update -y || { echo "Failed to update packages"; exit 1; } 

    # Extract Nexus and rename the directory
    echo "Extracting Nexus and renaming it"
    sudo tar -xvzf nexus-3.45.0-01-unix.tar.gz || { echo "Failed to extract Nexus archive"; exit 1; }
    sudo mv nexus-3.45.0-01 nexus || { echo "Failed to rename Nexus directory"; exit 1; }

    # Clean up the downloaded archive
    echo "Cleaning up downloaded archive"
    rm -f "$NEXUS_TAR"
fi

echo "Setting Permissions"
sudo chown -R nexus:nexus /opt/nexus
[ -d /opt/sonatype-work ] || sudo mkdir /opt/sonatype-work
sudo chown -R nexus:nexus /opt/sonatype-work || { echo "Failed to set permissions"; exit 1; }

echo "Configuring Nexus"
echo 'run_as_user="nexus"' | sudo tee /opt/nexus/bin/nexus.rc > /dev/null || { echo "Failed to configure Nexus"; exit 1; }      

echo "Creating a Systemd Service File for Nexus"        
echo "[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/nexus.service > /dev/null || { echo "Failed to create Nexus service file"; exit 1; } 

echo "Starting and Enabling Nexus Service"
# sudo systemctl daemon-reload || { echo "Failed to reload systemd"; exit 1; }
# sudo systemctl start nexus || { echo "Failed to start Nexus"; exit 1; }
# sudo systemctl enable nexus || { echo "Failed to enable Nexus"; exit 1; }
sh ~/nexus/bin/nexus start || { echo "Failed to start Nexus"; exit 1; }   

echo "Nexus installation and setup completed successfully!"
