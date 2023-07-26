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