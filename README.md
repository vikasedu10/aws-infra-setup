# Infrastructure automation repository for devOps
# Shell Script for EKS Cluster Provisioning and Automation
 This repository contains a shell script that automates the provisioning of an EKS cluster, installation of EBS CSI driver, API UI setup with a database using pgAdmin, Ingress configuration, and Keycloak setup.
 ## Prerequisites
 Before running the script, ensure that you have the following prerequisites:
 - AWS CLI installed and configured with appropriate credentials
- kubectl installed and configured
- Helm installed
 ## Usage
 1. Clone this repository:
shell
   git clone https://github.com/your-username/repository-name.git
2. Navigate to the repository directory:
shell
   cd repository-name
3. Make the shell script executable:
shell
   chmod +x script.sh
4. Open the  `script.sh`  file and modify the variables at the beginning of the file according to your environment and requirements.
 5. Run the script:
shell
   ./script.sh
The script will execute the following steps:
    - Provision an EKS cluster on AWS
   - Install the EBS CSI driver
   - Setup API UI with a PostgreSQL database using pgAdmin
   - Configure Ingress for the cluster
   - Setup Keycloak for authentication and authorization
 6. Monitor the script execution for any errors or prompts for input.
 7. Once the script completes successfully, you will have a fully provisioned and configured EKS cluster with the required components.

 ## Detailed Explanation of this repository
 - This Bash script is designed to set up a Kubernetes (K8s) cluster on Amazon Web Services (AWS) using the Elastic Kubernetes Service (EKS). It clones two repositories, builds Docker images from them, and then deploys the applications on the K8s cluster. It also sets up an AWS Elastic Block Store (EBS) Container Storage Interface (CSI) driver for persistent storage.

 ### Here's a step-by-step breakdown of the script: 
 1. The script checks if the necessary AWS environment variables are set, and if not, it prompts the user to set them. 
 2. It sets several variable values for the AWS region, repository names, cluster name, etc. 
 3. It defines several functions to install necessary tools like Docker, Kubectl, AWS CLI, EKSCTL, NPM, and Helm if they are not already installed. 
 4. The  configure_ssh  function configures SSH to keep the connection alive. 
 5. The  clone_repositories  function clones two repositories from GitHub. 
 6. The  set_aws_credentials  function sets AWS credentials. 
 7. All the defined functions are then called to install the necessary tools, configure SSH, clone repositories, and set AWS credentials. 
 8. It gets the AWS account number using the AWS CLI. 
 9. It creates an EKS cluster using EKSCTL and updates the Kubeconfig file. 
 10. It creates two repositories in AWS Elastic Container Registry (ECR) and logs in to the ECR. 
 11. It builds Docker images for the UI and API applications, pushes them to ECR, and deploys them to the K8s cluster. 
 12. It configures Ingress using Helm. 
 13. It applies additional tools (pgAdmin4 and Postgres) to the cluster. 
 14. It updates the deployments with the new images from ECR. 
 15. It configures the AWS EBS CSI driver for persistent storage. 
 16. It creates a secret in the K8s cluster to store the AWS credentials. 
 17. It installs the EBS CSI driver using Helm and upgrades it to the latest version. 
 18. Finally, it checks if the driver installation was successful by listing the pods in the kube-system namespace with the driver's label.
 ## License
 This project is licensed under the [MIT License](LICENSE.md).
 ## Contributing
 Contributions are welcome! If you find any issues or have suggestions, feel free to open an issue or submit a pull request.
 ## Acknowledgments
 - [AWS CLI](https://aws.amazon.com/cli/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
- [Helm](https://helm.sh/)
 ## Contact
 For any inquiries or questions, please contact [your-email@example.com](mailto:your-email@example.com).
 ---
Note: Replace  `your-username`  and  `repository-name`  with your actual GitHub username and repository name, respectively.