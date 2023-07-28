#!/bin/bash
set -e # exit on error

if [ -z "$AWS_ACCESS_KEY_ENV" ] || [ -z "$AWS_SECRET_KEY_ENV" ] || [ -z "$PAT_TOKEN_ENV" ]
then
  echo
  echo -e "AWS Access Key or Secret Key ENV not set." 
  echo -e "Set env using \nexport AWS_ACCESS_KEY_ENV=''\nexport AWS_SECRET_KEY_ENV=''\nexport PAT_TOKEN_ENV=''"
  echo
  exit 1
fi

echo "Creating variables.."
AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ENV
AWS_SECRET_KEY=$AWS_SECRET_KEY_ENV
PAT_TOKEN=$PAT_TOKEN_ENV
REGION=us-east-1

# Variables for AWS EKS Cluster Setup
API_REPO_NAME="https://$PAT_TOKEN@github.com/vikasedu10/k8s-demo-api.git"
UI_REPO_NAME="https://$PAT_TOKEN@github.com/vikasedu10/k8s-demo-ui.git"
CLUSTER_NAME=eks-demoapp
NODEGROUP_NAME=node-group-demoapp
API_REPO=testapi
UI_REPO=testui
FOLDER_PATH=../
NAMESPACE=eternal

NODE_TYPE=t3.medium
NODES=2
NODES_MAX=4
NODES_MIN=2

# Variables for AWS EBS CSI Setup
EBS_CSI_DRIVER="aws-ebs-csi-driver"

function install_docker() {
    if command -v docker > /dev/null 2>&1; then
        echo "Docker is already installed. Skipping Installation"
    else
        echo "Installing Docker"
        sudo apt update
        sudo apt install docker.io -y
        sudo usermod -a -G docker $USER
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo chmod 777 /var/run/docker.sock
    fi
}

function install_kubectl() {
    if command -v kubectl > /dev/null 2>&1; then
        echo "Kubectl is already installed. Skipping Installation"
    else
        echo "Installing kubectl"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        echo 'alias k=kubectl' >>~/.bashrc
        echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
        source ~/.bashrc
        rm -rf kubectl
    fi
}

function install_aws_cli() {
    if command -v aws > /dev/null 2>&1; then
        echo "AWS CLI is already installed. Skipping Installation"
    else
        echo "Installing aws cli"
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        sudo apt install unzip -y
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi
}

function install_eksctl() {
    if command -v eksctl > /dev/null 2>&1; then
        echo "EKSCTL is already installed. Skipping Installation"
    else
        echo "Installing eksctl"
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/eksctl /usr/local/bin
        eksctl version
    fi
}

function install_npm() {
    if command -v npm > /dev/null 2>&1; then
        echo "NPM is already installed. Skipping Installation"
    else
        echo "Installing npm"
        curl -fsSL https://deb.nodesource.com/setup_19.x | sudo -E bash - &&
        sudo apt-get install -y nodejs
    fi
}

function install_helm() {
    if command -v helm > /dev/null 2>&1; then
        echo "Helm is already installed. Skipping Installation"
    else
        echo "Install Helm"
        wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
        tar -zxvf helm-v3.12.0-linux-amd64.tar.gz
        sudo mv linux-amd64/helm /usr/local/bin/helm
        rm -rf linux-amd helm-v3.12.0-linux-amd64.tar.gz
        rm -rf linux-amd64
    fi
}

function configure_ssh() {
    echo 
    echo 'ClientAliveInterval 60' | sudo tee --append /etc/ssh/sshd_config
    sudo service ssh restart
}

function clone_repositories() {
    API_REPO_NAME=$(basename -s .git "$1")
    UI_REPO_NAME=$(basename -s .git "$2")
    echo "Cloning sample UI & API repository"
     git clone $1 ../$API_REPO_NAME
     git clone $2 ../$UI_REPO_NAME
}

function set_aws_credentials() {
    aws configure set aws_access_key_id $1
    aws configure set aws_secret_access_key $2
    aws configure set default.REGION $3
}

# Call all the functions to install and setup the required tools
install_docker
install_kubectl
install_aws_cli
install_eksctl
install_npm
install_helm
configure_ssh
clone_repositories $UI_REPO_NAME $API_REPO_NAME
set_aws_credentials $AWS_ACCESS_KEY $AWS_SECRET_KEY $REGION 

# Setting dependent variables
ACN=$(aws sts get-caller-identity --query 'Account' --output text)

# Setup EKS Cluster 
function log() {
    echo
    echo "$1"
    echo
}

function execute() {
    echo
    echo "########### -->"
    log "Executing: $1"
    eval $1

    if [ $? -ne 0 ]; then
        echo
        echo "########### -->"
        echo "Error while executing: $1"
        exit 1
    fi
}

# Create cluster with EKSCTL CLI
execute "eksctl create cluster --name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME --nodes $NODES --node-type $NODE_TYPE --nodes-max $NODES_MAX --nodes-min $NODES_MIN --region $REGION"
execute "aws eks update-kubeconfig --name $CLUSTER_NAME"

# Create sample UI & API repos in AWS ECR
execute "aws ecr create-repository --repository-name $UI_REPO --region $REGION"
execute "aws ecr create-repository --repository-name $API_REPO --region $REGION"
execute "aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACN.dkr.ecr.$REGION.amazonaws.com"

# Update deployment images using command
execute "docker build -t $ACN.dkr.ecr.$REGION.amazonaws.com/$UI_REPO:v1 -f $FOLDER_PATH/k8s-demo-ui/Dockerfile $FOLDER_PATH/k8s-demo-ui/. && docker push $ACN.dkr.ecr.$REGION.amazonaws.com/$UI_REPO:v1"
execute "docker build -t $ACN.dkr.ecr.$REGION.amazonaws.com/$API_REPO:v1 -f $FOLDER_PATH/k8s-demo-api/Dockerfile $FOLDER_PATH/k8s-demo-api/. && docker push $ACN.dkr.ecr.$REGION.amazonaws.com/$API_REPO:v1"

# Setup namespace
echo "Setup $NAMESPACE namespace"
execute "kubectl create namespace $NAMESPACE"
execute "kubectl config set-context --current --namespace=$NAMESPACE"
execute "kubectl config view --minify | grep namespace:"

# Deploy API, UI, Ingress resources
execute "kubectl apply -f $FOLDER_PATH/k8s-demo-ui/ui.yaml"
execute "kubectl apply -f $FOLDER_PATH/k8s-demo-api/api.yaml"

# Configure Ingress
execute "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
execute "helm repo update"
execute "helm pull ingress-nginx/ingress-nginx"
execute "helm install ingress-nginx ingress-nginx/ingress-nginx --namespace $NAMESPACE"

# Apply tools
execute "kubectl apply -f $FOLDER_PATH/infra/pgadmin4.yaml"
execute "kubectl apply -f $FOLDER_PATH/infra/postgres.yaml"

# Update deployments
execute "kubectl set image deployment/$UI_REPO $UI_REPO=$ACN.dkr.ecr.$REGION.amazonaws.com/$UI_REPO:v1"
execute "kubectl set image deployment/$API_REPO $API_REPO=$ACN.dkr.ecr.$REGION.amazonaws.com/$API_REPO:v1"


echo "Configuring AWS EBS CSI driver..."
oidc_id=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

if ! aws iam list-open-id-connect-providers | grep -q $oidc_id; then
  execute "eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve"
fi

execute "eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve"

execute "aws eks describe-addon-versions --addon-name aws-ebs-csi-driver"

execute "echo 'AWS EBS CSI driver add-on configured'"

execute "echo "Installing AWS EBS CSI driver as self-hosted using Helm""

execute "kubectl create secret generic aws-secret \
    --namespace kube-system \
    --from-literal 'key_id=${AWS_ACCESS_KEY}' \
    --from-literal 'access_key=${AWS_SECRET_KEY}'"

execute "helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
execute "helm repo update"

execute "echo "Upgrading to latest version of driver""
execute "helm upgrade --install $EBS_CSI_DRIVER \
    --namespace kube-system \
    aws-ebs-csi-driver/$EBS_CSI_DRIVER"

execute "kubectl get pods -n kube-system -l app.kubernetes.io/name=$EBS_CSI_DRIVER"

echo "Driver installation completed successfully"
