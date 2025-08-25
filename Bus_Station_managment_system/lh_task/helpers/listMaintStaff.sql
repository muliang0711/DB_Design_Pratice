select staffID 
from staff s 
join staffrole sr on s.roleid = sr.roleid 
where LOWER(sr.rolename) LIKE '%maintenance%'
order by staffid;