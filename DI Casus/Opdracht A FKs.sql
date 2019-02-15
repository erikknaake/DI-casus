USE Course
go


/*******************************************************************************************
	FK emp -> dept
*******************************************************************************************/
ALTER TABLE emp
	ADD CONSTRAINT FK_emp_dept
	FOREIGN KEY (deptno) REFERENCES dept(deptno)
go


/*******************************************************************************************
	FK dept -> emp
*******************************************************************************************/
ALTER TABLE dept
	ADD CONSTRAINT FK_dept_emp
	FOREIGN KEY (mgr) REFERENCES emp(empno)
go


/*******************************************************************************************
	FK hist -> dept
*******************************************************************************************/
ALTER TABLE hist
	ADD CONSTRAINT FK_hist_dept
	FOREIGN KEY (deptno) REFERENCES dept(deptno)
go


/*******************************************************************************************
	FK hist -> emp (ON DELETE CASCADE)
*******************************************************************************************/
ALTER TABLE hist
	ADD CONSTRAINT FK_hist_emp
	FOREIGN KEY (empno) REFERENCES emp(empno)
	ON DELETE CASCADE
go


/*******************************************************************************************
	FK memp -> emp (manager)
*******************************************************************************************/
ALTER TABLE memp
	ADD CONSTRAINT FK_memp_emp_mgr
	FOREIGN KEY (mgr) REFERENCES emp(empno)
go


/*******************************************************************************************
	FK memp -> emp (empno)
*******************************************************************************************/
ALTER TABLE memp
	ADD CONSTRAINT FK_memp_emp_empno
	FOREIGN KEY (empno) REFERENCES emp(empno)
go


/*******************************************************************************************
	FK reg -> emp (ON DELETE CASCADE)
*******************************************************************************************/
ALTER TABLE reg
	ADD CONSTRAINT FK_reg_emp
	FOREIGN KEY (stud) REFERENCES emp(empno)
	ON DELETE CASCADE
go


/*******************************************************************************************
	FK emp -> grd (ON UPDATE CASCADE)
*******************************************************************************************/
ALTER TABLE emp
	ADD CONSTRAINT FK_emp_grd
	FOREIGN KEY (sgrade) REFERENCES grd(grade)
	ON UPDATE CASCADE
go


/*******************************************************************************************
	FK term -> emp (ON DELETE CASCADE)
*******************************************************************************************/
ALTER TABLE term
	ADD CONSTRAINT FK_term_emp
	FOREIGN KEY (empno) REFERENCES emp(empno)
	ON DELETE CASCADE
go


/*******************************************************************************************
	FK srep -> emp (ON DELETE CASCADE)
*******************************************************************************************/
ALTER TABLE srep
	ADD CONSTRAINT FK_srep_emp
	FOREIGN KEY (empno) REFERENCES emp(empno)
	ON DELETE CASCADE
go