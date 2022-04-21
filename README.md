# Cleaning-Data-SQL

I used SQL (MySQL Workbench) to clean and transform raw housing data in Nashville, TX into a more usable data set for analysis. 
Following is my cleaning process:
* Standardizing the Date format (from string to date)
* Filling in NULL Property Address data
* Breaking out Address into Individual Columns (Address, City, State)
* Changing 'Y' and 'N' to 'Yes' and 'No' in certain field
* Removing duplicates
