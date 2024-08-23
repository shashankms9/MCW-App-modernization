# .NET App Modernization
---
## Estimated Duration: 4.5 Hours

## Overview
In this hands-on lab, you will migrate a legacy on-premises application to Microsoft Azure using various Azure services and tools. Over the years, cloud computing has revolutionized how applications are hosted and managed, offering benefits such as scalability, security, and reduced infrastructure overhead. Azure provides a comprehensive suite of tools and services to facilitate the seamless migration of applications and databases from on-premises environments to the cloud.

In this lab, we will guide you through the process of setting up Azure Migrate, assessing your existing on-premises application, and migrating it to Azure App Service using the App Service Migration Assistant. You will also learn how to migrate on-premises databases to Azure SQL Database and enhance the application's functionality with Azure's serverless offerings, such as Azure Functions. Additionally, we'll cover the setup of a CI/CD pipeline using GitHub Actions to automate deployments and explore advanced topics like securing application secrets with Azure Key Vault, performance testing, and deploying the application using Azure Application Gateway and Firewall. 

By the end of this lab, you will gain hands-on experience in modernizing applications for the cloud, implementing cloud-native services, and leveraging Azure's capabilities to improve scalability, security, and performance.

## Lab objectives
In this lab, you will complete the following tasks:
   - **Review the Legacy On-Prem Application**: Analyze the existing on-premises application architecture and dependencies to understand the migration requirements and potential challenges.
   - **Setting up Azure Migrate**: Configure Azure Migrate to assess the on-premises environment and prepare it for migration to Azure.
   - **Migrate your application with App Service Migration Assistant**: Use the App Service Migration Assistant to move the legacy web application to Azure App Service with minimal downtime.
   - **Migrate the on-premises database to Azure SQL Database**: Migrate the on-premises database to Azure SQL Database to take advantage of managed database services and high availability.
   - **Setup CI/CD pipeline with GitHub Actions for the web app**: Implement a continuous integration and continuous deployment (CI/CD) pipeline using GitHub Actions to automate the build, test, and deployment process for the web application.
   - **Using serverless Azure Functions to process orders**: Develop and deploy serverless Azure Functions to handle order processing, reducing infrastructure management overhead and improving scalability.
   - **Publish the application via Application Gateway and Firewall (Optional)**: Secure and optimize the application's deployment using Azure Application Gateway and Firewall for enhanced traffic management and protection.
   - **Performance testing of web app (Optional)**: Conduct performance testing on the migrated web application to identify bottlenecks and ensure it meets performance standards.
   - **Securing web app connection string with Azure Key Vault and Managed Identity (Optional)**: Enhance the security of the web application by using Azure Key Vault and Managed Identity to securely manage and access sensitive connection strings.

## Pre-requisites

## Architecture
In this hands-on lab, the architecture flow comprises several key components. You'll start by deploying the web application on Azure App Service and setting up the necessary Azure resources. The core of this architecture is the e-commerce web application hosted on Azure App Service, which interacts with various Azure services to provide a seamless user experience. The Azure SQL Database serves as the primary data store, maintaining the product catalog and user information. Orders submitted by users are placed in Azure Queue Storage, enabling reliable communication between the front-end and back-end components. Azure Functions then process these queued orders, performing tasks such as order validation and inventory updates. Additionally, Azure Blob Storage is used for storing invoices, and Azure Application Insights provides monitoring and performance management. The CI/CD pipeline, managed by GitHub Actions, automates deployments, ensuring efficient application updates and integration.

## Architecture Diagram

![This solution diagram includes a high-level overview of the architecture implemented within this hands-on lab.](media/architecture-diagram.png "Solution architecture diagram")

## Explanation of Components

- **Azure App Service**: A managed platform for deploying and scaling web applications and APIs, supporting multiple languages with built-in security, auto-scaling, and load balancing.

- **Azure SQL Database**: A fully managed relational database service for storing application data, providing high availability, scalability, and security.

- **Azure Queue Storage**: A message queuing service for storing large numbers of messages to enable reliable and decoupled communication between application components.

- **Azure Functions**: A serverless compute service that executes code in response to events, used here for processing orders and managing business logic dynamically.

- **Azure Blob Storage**: A scalable object storage solution for unstructured data, used to store invoices and other multimedia files with high durability and availability.

- **Azure Application Insights**: An application performance management tool that provides real-time monitoring, diagnostics, and analytics to ensure optimal app performance.

- **GitHub Actions**: A CI/CD tool integrated with GitHub for automating build, test, and deployment workflows, ensuring continuous integration and delivery.

## Getting Started with Lab

1. Once the environment is provisioned, a virtual machine (JumpVM) and lab guide will get loaded in your browser. Use this virtual machine throughout the workshop to perform the lab. You can see the number on the lab guide bottom area to switch to different exercises of the lab guide.
   

   ![](media/Getting_started01.png "Lab Environment")

1. To get the lab environment details, you can select the **Environment Details** tab. Additionally, the credentials will also be emailed to your email address provided during registration. You can also open the Lab Guide on separate and full window by selecting the **Split Window** from the lower right corner. Also, you can start, stop, and restart virtual machines from the **Resources** tab.

   ![](media/Getting_started03.png "Lab Environment")
 
    > You will see SUFFIX value on the **Environment Details** tab, use it wherever you see SUFFIX or Deployment ID in lab steps.


## Login to Azure Portal

1. In the JumpVM, click on the Azure portal shortcut of Microsoft Edge browser from the desktop.

   ![](media/Getting_started02.png "Lab Environment")

1. In the Welcome to Microsoft Edge page, select **Start without your data** and on the help for importing Google browsing data page select **Continue without this data** button and proceed to select **Confirm and start browsing** on the next page.
   
1. On **Sign in to Microsoft Azure** tab you will see login screen, enter following email/username and then click on **Next**. 
   * Email/Username: <inject key="AzureAdUserEmail"></inject>
   
     ![](media/image7.png "Enter Email")
     
1. Now enter the following password and click on **Sign in**.
   * Password: <inject key="AzureAdUserPassword"></inject>
   
     ![](media/image8.png "Enter Password")
     
1. If you see the pop-up **Stay Signed in?**, click No

1. If you see the pop-up **You have free Azure Advisor recommendations!**, close the window to continue the lab.

1. If a **Welcome to Microsoft Azure** popup window appears, click **Maybe Later** to skip the tour.
   
1. Now you will see Azure Portal Dashboard, click on **Resource groups** from the Navigate panel to see the resource groups.

    ![](media/select-rg.png "Resource groups")
   
1. Confirm you have a resource group present with name **hands-on-lab-<inject key="DeploymentID" enableCopy="false" />**. Last six digits in the resource group name are unique for every user.

    ![](media/image10.png "Resource groups")
   
1. Now, click on Next from the lower right corner to move to the next page.

## Support Contact
 
1. The CloudLabs support team is available 24/7, 365 days a year, via email and live chat to ensure seamless assistance at any time. We offer dedicated support channels tailored specifically for both learners and instructors, ensuring that all your needs are promptly and efficiently addressed.
 
   Learner Support Contacts:
 
   - Email Support: labs-support@spektrasystems.com
   - Live Chat Support: https://cloudlabs.ai/labs-support
 
1. Now, click on Next from the lower right corner to move on to the next page.
## Happy Learning!!
