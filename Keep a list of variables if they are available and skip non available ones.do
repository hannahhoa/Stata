/* 
	. Suppose that you have many datasets. You want to keep a list of variables. However, some variables may not be available in some datasets. In that case, if you use the "keep [varlist]" command, it will cause an error when a dataset does not contain a certain variable in varlist. That error will also terminate the rest of the do file.

	. We want to keep a list of variables which are available while skipping ones which are not available, yet facing no error. This do file will show you step-by-step how to do that.

	. Let's keep all datasets in the same folder. 
*/

** Let's call the directory to that folder "datasource"
	global datasource "put_your_directory_here"

** 1 Obtain all .dta file names from the directory of that folder 
	local filelist: dir "$datasource" files "*.dta"
	
	
** 2 Display file names
	di `filelist'
		
		
** 3 Write a loop that goes through every dataset in that folder
	foreach filename of local filelist {
		* Display filename which is being processed
		di "File `filename' is being processed"
		
		* Assign all variables we'd like to keep into a list called "masterlist"
		local masterlist "var_name1 var_name2 var_name3"
		
		* Create an empty object named "available_vars" to store available variables later
		local available_vars=""
		
		* Store available variables into the object "available_vars"
		foreach i of local masterlist {
			// Confirm if variable i exists
			cap confirm variable `i' 
			
			// If exist, the returning code "_rc" is non-missing. In such case, store that variable into "available_vars"
			if !_rc { 
				local available_vars "`available_vars' `i'"
			}
		}
		
		* Keep available vars
		keep `available_vars'
		
		* Save new data
		save `"$datasource/new_`filename'"', replace
	}
	
	
	
* End *	