
# Getting Started with Lab

1. Once the environment is provisioned, a virtual machine (JumpVM) and lab guide will get loaded in your browser. Use this virtual machine throughout the workshop to perform the the lab. You can see the number on lab guide bottom area to switch on different exercises of lab guide.
   

   ![](media/appmod-1.png "Lab Environment")

1. To get the lab environment details, you can select **Environment Details** tab. Additionally, the credentials will also be emailed to your email address provided at registration. You can also open the Lab Guide on seprate and full window by selcting the **Split Window** from lower right corner. Also, you can start, stop and restart virtual machines from **Virtual Machines** tab.

   ![](media/cloudlabs-env-page.png "Lab Environment")
 
    > You will see SUFFIX value on **Environment Details** tab, use it whereever you see SUFFIX or DeploymentID in lab steps.


## Login to Azure Portal
1. In the JumpVM, click on Azure portal shortcut of Microsoft Edge browser which is created on desktop.

   ![](media/labenv-1.png "Lab Environment")

1. In the Welcome to Microsoft Edge page, select **Start without your data** and on the help for importing Google browsing data page select the **Continue without this data** button and procced to select **Confirm and start browsing** in the next page.
   
1. On **Sign in to Micsoft Azure** tab you will see login screen, in that enter following email/username and then click on **Next**. 
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
   
1. Confirm you have a resource group present with name **hands-on-lab-<inject key="DeploymentID" enableCopy="false" />**. Last six digits in resource group name is unique for everyone.

    ![](media/image10.png "Resource groups")
   
1. Now, click on the **Next** from lower right corner to move on next page.
