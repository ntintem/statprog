%macro char_subgroups;
	%local i;
	%do i=1 %to &subgroup_char_vars_size;
		&&subgroup_char_var&i
	%end;
%mend char_subgroups;
