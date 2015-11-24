# POC-CA-Annual-Report
A repository for sharing the scripts for creating the 2015 Annual Report measures.

## Included Measures

- CFSR Meaures

    - Maltreatment in foster care (safety)
    - Recurrence of maltreatment (safety)
    - Permanency in 12 months for children entering foster care
    - Permanency in 12 months for children in foster care 12 to 23 months
    - Permanency in 12 months for children in foster care for 24 months or longer
    - Re-entry to foster care in 12 months (permanency)
    - Placement stability (permanency)

- POC Measures
    
    - Permanency in 12 months for children who are legally free
    - Reports (safety)
    - Screened-In Reports (safety)
    - Placement Rate (safety)

## Using the Code in this Repository

Each of the folders contain measures has a readme describing the process of creating tables with the scripts provided. However, prior to creating these tables, the AFCARS and NCANDS data needs to be extracting. This can be done by going to the folder [SSIS for AFCARS and NCANDS](https://github.com/pocdata/POC-CA-Annual-Report/tree/master/Dependencies/SSIS%20for%20AFCARS%20and%20NCANDS) which is in the dependencies folder. The NCANDS data does need to be processed in anyway for the measures, but the AFCARS data does. Once the AFCARS data has been loaded into the database, the script in [preparing AFCARS data for analysis](https://github.com/pocdata/POC-CA-Annual-Report/tree/master/Dependencies/preparing%20AFCARS%20data%20for%20analysis) must be run to create the table that is used by the CFSR measures.
