# salesforce-packaging-script
Script for developing a salesforce second generation managed package
Requirements:
1) PowerShell installed
2) IDE (VSCode Prefered)

Preparation:
1) Create a specific folder por the version development
2) Paste the packaging folder containing all of the scripts
3) Run main.ps1

Steps:
1) Setup the partner bussiness org that has the Dev Hub (For creating scratch orgs and )
2) Configure the sourceOrg (this is your development org retrieving metadata or creating package.xml)
3) Configure a scratch org for isolating your components for edition and for posterior retrieval of package.xml for package development (use the scratch definition file on packaging\config\unmanaged-scratch-def.json)
4) Once the unmanaged Scratch Org is created and the sourceOrg configured you can retrieve the data from the source org using the package.xml file on the unmanagedScratchOrg/manifest directory (option 5)
 or by specifying an unmanaged package name (this will create a package.xml for the package too)(option 4).
5) Create a DXproject for package development
6) Edit the project.json file on DXproject directory according to your packages need.
7) If needed edit the script on packaging\filesForPreprocessing\preProcessingScript.ps1 to define steps to be performed before the packaging process begins
8) Create another scratch Org for installing the newly created package (using the same as before may result in conflicts with objects.)
9) Create Package Version (you can perform the necessary steps here such as: Package creation, Scanns running, Prepackaging, package version promotion, package installation)
10) Reset setup if you want to reconfigure the steps above
