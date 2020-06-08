--创建数据库
CREATE DATABASE BMS ON 
	( NAME = 'BMS', FILENAME = 'D:\BMS.mdf',
	  SIZE = 10, FILEGROWTH = 5)
LOG ON 
	(NAME = 'BMSlog', FILENAME = 'D:\BMSlog.ldf')

/**************创建表*******************/
--创建管理员表
CREATE TABLE  Adimistration( 
	a_no CHAR(10) Primary Key, 
	a_name VARCHAR(30),
	a_password VARCHAR(20))

--创建用户类型表
CREATE TABLE  UserType( 
	u_type VARCHAR(20) Primary Key, 
	u_borrow_total_num SMALLINT, 
	u_borrow_days INT )

--创建用户表
CREATE TABLE UserList( 
	u_no CHAR(10) Primary Key, 
	u_name VARCHAR(30) NOT NULL,
	u_password VARCHAR(20),
	u_type VARCHAR(20) NOT NULL,
	u_phone VARCHAR(30),
	u_borrow_now_num SMALLINT,
	u_late SMALLINT ,
	Foreign Key (u_type) references UserType(u_type) ON UPDATE CASCADE)

--创建出版社表
CREATE TABLE Publish(
	p_name VARCHAR(20) Primary Key,
	p_address VARCHAR(20),
	p_phone VARCHAR(30))
	
--创建分类表
CREATE TABLE FClassify(
	f_no CHAR(10) Primary Key,
	f_name VARCHAR(20),
	f_location VARCHAR(20))
	 
--创建书籍表
CREATE TABLE Book ( 
	b_no CHAR(10) Primary Key,
	b_name VARCHAR(30),
	b_author VARCHAR(20),
	b_publish VARCHAR(20),
	b_price MONEY,
	b_fno CHAR(10),
	b_year CHAR(10),
	Foreign Key (b_fno) references FClassify(f_no) ON UPDATE CASCADE,
	Foreign Key (b_publish) references Publish(p_name) ON UPDATE CASCADE)

--创建索引号表
CREATE TABLE IndexNo(
	i_bno CHAR(10),
	i_sno VARCHAR(20),
	i_ino VARCHAR(20) Primary Key,
	Foreign Key (i_bno) references Book(b_no)ON DELETE CASCADE ON UPDATE CASCADE)

--创建图书副本表
CREATE TABLE Copy(
	c_ino VARCHAR(20) Primary Key,
	c_enterdate DATETIME NOT NULL,
	c_state VARCHAR(10) NOT NULL,
	c_location VARCHAR(20) NOT NULL,
	Foreign Key (c_ino) references IndexNo(i_ino)ON DELETE CASCADE ON UPDATE CASCADE)

--创建借阅记录表
CREATE TABLE DataBorrow(
	d_ino VARCHAR(20),
	d_uno CHAR(10),
	d_lenddate DATETIME,
	d_returndate DATETIME,
	d_state VARCHAR(10) NOT NULL,
	d_actual DATETIME,
	Primary Key(d_ino,d_uno,d_lenddate),
	Foreign Key (d_ino) references IndexNo(i_ino),
	Foreign Key (d_uno) references UserList(u_no))


/*****************触发器(需单独一个一个运行！！！)*********************/
--触发器user_init初始化用户表，正在借阅数量和迟还次数为0，用户类型为普通用户
CREATE TRIGGER user_init ON UserList
FOR INSERT  
AS DECLARE @u_no char(10), @u_borrow_now_num smallint, @u_late smallint,@u_type varchar(20);
select @u_borrow_now_num  = u_borrow_now_num,@u_late=u_late ,@u_no = u_no from inserted;
update userlist SET u_borrow_now_num = 0 where u_no = @u_no;
update userlist SET u_late = 0 where u_no = @u_no;
update userlist SET @u_type = '普通用户' where u_no = @u_no;
print'注册成功'
--插入格式为：
--INSERT INTO UserList VALUES('','','普通用户','',null,null)

--触发器copy_init初始化图书副本未借出
CREATE TRIGGER copy_init ON Copy
FOR INSERT  
AS DECLARE @c_ino char(10), @c_state varchar(10);
select @c_ino = c_ino from inserted;
update copy SET c_state = '未借出' where c_ino = @c_ino;
print'添加图书成功'
--插入格式为：
--INSERT INTO Copy VALUES('','','0','')

--触发器lend_data出借记录
CREATE TRIGGER lend_data ON DataBorrow
FOR INSERT  
AS DECLARE @d_ino char(10), @c_state varchar(10),@c_ino varchar(20),@days int,@u_no char(10),
@u_borrow_now_num smallint,@u_borrow_max smallint,@state varchar(10),@迟还次数 SMALLINT;
select @d_ino = d_ino,@u_no = d_uno from inserted;
select @days = u_borrow_days from UserType,UserList  WHERE UserType.u_type = UserList.u_type
SELECT @u_borrow_max = u_borrow_total_num FROM UserType,UserList  WHERE UserType.u_type = UserList.u_type AND UserList.u_no = @u_no;
SELECT @u_borrow_now_num = u_borrow_now_num FROM UserType,UserList  WHERE UserType.u_type = UserList.u_type AND UserList.u_no = @u_no;
SELECT @state = c_state FROM Copy WHERE c_ino = @d_ino;
SELECT @迟还次数 = u_late FROM UserList WHERE u_no = @u_no;
IF(@state = '借出')BEGIN
ROLLBACK TRANSACTION
PRINT'图书已借出'
END 
ELSE IF(@迟还次数 > 10)BEGIN
ROLLBACK TRANSACTION
PRINT'迟还次数达到十次，信誉度过低不可借书'
END 
ELSE IF(@u_borrow_now_num < @u_borrow_max) BEGIN
ALTER TABLE databorrow DISABLE TRIGGER return_data  
--出借时间
update DataBorrow SET d_lenddate = GETDATE() where d_ino = @d_ino AND d_uno = @u_no AND d_state <> '已归还';
--应归还时间
update DataBorrow SET d_returndate = GETDATE()+ @days where d_ino = @d_ino AND d_uno = @u_no AND d_state <> '已归还';
--归还状态
update DataBorrow SET d_state = '未归还' where d_ino = @d_ino AND d_uno = @u_no AND d_state <> '已归还';
--用户正在阅读数量更新
ALTER TABLE databorrow ENABLE TRIGGER return_data
update UserList SET u_borrow_now_num = u_borrow_now_num + 1 where u_no = @u_no;
--图书出借状态
update Copy SET c_state = '借出' where c_ino = @d_ino;
END
ELSE IF(@u_borrow_now_num = @u_borrow_max) BEGIN
PRINT'你已经达到借阅的最大数目了'
DELETE FROM DataBorrow WHERE d_state = '0'
END
--插入格式为：
--INSERT INTO databorrow VALUES('','','2020-01-01',NULL,'0',NULL)

--触发器return_date归还记录
CREATE TRIGGER return_data ON DataBorrow 
FOR UPDATE
AS DECLARE @d_actual DATETIME,@d_returndate DATETIME,@money int,@u_no char(10),@d_ino varchar(20),@d_state varchar(10),@borrowtime DATETIME
select @d_state = d_state from inserted;
select @u_no = d_uno from inserted;
select @d_ino = d_ino from inserted;
select @d_returndate = d_returndate from inserted;
select @borrowtime = d_lenddate from inserted;
if(@d_state = '已归还') begin
--实归还时间
update DataBorrow SET d_actual = GETDATE() where d_ino = @d_ino AND d_uno = @u_no AND d_lenddate=@borrowtime;
select @d_actual = d_actual from databorrow where d_uno = @u_no and d_ino = @d_ino AND d_lenddate=@borrowtime;
--select  datediff(day,@d_returndate,@d_actual) as '时间差'
select @money = datediff(day,@d_returndate,@d_actual)
if(@money>0) begin
	UPDATE UserList set u_late = u_late + 1 where u_no = @u_no;
	print'需要支付/元：'print @money 
	end 
--图书状态
update Copy SET c_state = '未借出' where c_ino = @d_ino;
--借阅记录表归还状态更新为已归还
update DataBorrow SET d_state = '已归还' where d_ino=@d_ino AND d_uno=@u_no AND d_lenddate=@borrowtime;
--用户正在阅读数量更新
update UserList SET u_borrow_now_num = u_borrow_now_num - 1 where u_no = @u_no;
end
--更新格式为：
--UPDATE DataBorrow SET d_state = '已归还' WHERE d_ino = '' AND d_uno = '' AND d_lenddate = ''


/***************约束**************/
--（在数据库中直接运行下面代码就可以）
--迟还次数不小于0
ALTER TABLE UserList ADD CONSTRAINT borrow_late_num CHECK (u_late >= 0 )
--正在借阅数不小于0
ALTER TABLE UserList ADD CONSTRAINT borrow_num_max CHECK(u_borrow_now_num >= 0)


/*****************数据添加(需按顺序单独一条一条运行！！！)*********************/
INSERT INTO Adimistration VALUES
('001','张大大','zdd'),
('002','刘铁柱', 'ltz'),
('003','吴敌', 'wd')

INSERT INTO Publish VALUES
('清华大学出版社', '北京', '15236948788'),
('晟威出版社', '天津', '14863254523'),
('南海出版公司', '海南', '15536485912'),
('上海文艺出版社', '上海', '13685493215')

INSERT INTO FClassify VALUES
('A','教材', '1F-A'),
('B','辅导书', '1F-B'),
('C','小说', '2F-C')

INSERT INTO Book VALUES
('00001','数据结构','严蔚敏','清华大学出版社','33.5','A','2005'),
('00002','幻夜', '东野圭吾','南海出版公司','45.2','C','2010'),
('00003','物理实验教程', '吴玉华','清华大学出版社','44.8','A','2008'),
('00004','考研指点', '张雪峰','晟威出版社','68.8','B','2019'),
('00005','纸上寻仙记', '郏宗培','上海文艺出版社','41.2','C','2012')

INSERT INTO IndexNo VALUES
('00001','01','0000101'),
('00001','02','0000102'),
('00002','01','0000201'),
('00002','02','0000202'),
('00002','03','0000203'),
('00003','01','0000301'),
('00003','02','0000302'),
('00004','01','0000401'),
('00005','01','0000501')

INSERT INTO Copy VALUES
('0000101','2019-1-10','未借出','1F-A1'),
('0000102','2019-1-10','未借出','1F-A1'),
('0000201','2019-11-23','未借出','2F-C3'),
('0000202','2019-11-23','未借出','2F-C3'),
('0000203','2020-1-23','未借出','2F-C3'),
('0000301','2019-1-10','未借出','1F-A1'),
('0000302','2019-12-24','未借出','1F-A1'),
('0000401','2019-1-10','未借出','1F-B7'),
('0000501','2019-1-10','未借出','2F-C5')

INSERT INTO Usertype VALUES
('普通用户','20','30'),
('中级用户','30','60'),
('高级用户','50','90')

INSERT INTO UserList VALUES
('111111','刘翠花','lch','普通用户','15638594562',0,0),
('527527','kiki','kiki','高级用户','13648952456',0,0),
('222222','曾威猛','zwm','普通用户','17736548225',0,0),
('333333','孙强','sq','中级用户','19832155267',0,0)

INSERT INTO Databorrow VALUES
('0000101','527527','2020','2020','0',null)

INSERT INTO Databorrow VALUES
('0000201','111111','2020','2020','0',null)

INSERT INTO Databorrow VALUES
('0000301','222222','2020','2020','0',null)

INSERT INTO Databorrow VALUES
('0000202','333333','2020','2020','0',null)

/*****************视图(需新建查询单独一条一条运行！！！)*********************/
--*视图1：用户总借阅数
CREATE VIEW User_borrow_num AS SELECT d_uno,COUNT(d_uno) total_borrow_num
FROM DataBorrow GROUP BY d_uno

--视图2：查询用户信息
CREATE VIEW User_info AS SELECT Userlist.u_no 用户号,UserList.u_name 用户名,UserList.u_type 用户类型,Userlist.u_phone 电话号码,
Userlist.u_borrow_now_num 当前借阅数,Userlist.u_late 迟还次数,Usertype.u_borrow_total_num 最大可借数,User_borrow_num.total_borrow_num 历史借阅数 
FROM UserType,Userlist LEFT OUTER JOIN User_borrow_num ON Userlist.u_no = User_borrow_num.d_uno WHERE UserType.u_type = UserList.u_type

--视图3：查询用户借阅信息
CREATE VIEW User_borrow_info AS SELECT DataBorrow.d_uno 用户号,UserList.u_name 用户名,DataBorrow.d_ino 索号,
book.b_name 书名,DataBorrow.d_lenddate 出借时间,DataBorrow.d_returndate 应归还间,Databorrow.d_actual 实归还时间,
DataBorrow.d_state 状态
FROM DataBorrow,Book,IndexNo,Userlist
WHERE DataBorrow.d_ino = IndexNo.i_ino AND IndexNo.i_bno = Book.b_no AND Userlist.u_no = DataBorrow.d_uno

--*视图4：书本总数信息
CREATE VIEW Book_num AS SELECT i_bno,COUNT(i_bno) total_num
FROM IndexNo  GROUP BY i_bno 

--*视图5：借阅关系+书号
CREATE VIEW Book_borrow_bno AS SELECT Databorrow.*,Book.b_no FROM DataBorrow,Book,IndexNo 
WHERE DataBorrow.d_ino = IndexNo.i_ino AND IndexNo.i_bno = Book.b_no

--*视图6：书本总借阅数信息
CREATE VIEW Book_borrow_num AS SELECT b_no,COUNT(b_no) total_borrow_num
FROM Book_borrow_bno GROUP BY b_no 

--视图7：书籍相关信息
CREATE VIEW Book_info AS SELECT Book.b_no 书号,b_name 书名,FClassify.f_name 类别,Book.b_author 作者,
Book.b_publish 出版社,Book.b_price 价格,Book_num.total_num 总数,Book_borrow_num.total_borrow_num 历史借阅数 
FROM FClassify,Book_num,Book LEFT OUTER JOIN Book_borrow_num ON Book.b_no = Book_borrow_num.b_no WHERE Book.b_no = Book_num.i_bno AND Book.b_fno = FClassify.f_no

--视图8：每本书具体借阅状态
CREATE VIEW Book_borrow_info AS SELECT Copy.c_ino 索引号,Book.b_name 书名,Book.b_author 作者,
Book.b_publish 出版社,Copy.c_state 状态,Copy.c_location 位置
FROM Copy,Book,IndexNo WHERE Book.b_no = IndexNo.i_bno AND IndexNo.i_ino = Copy.c_ino

/*************存储过程************/
--存储过程
CREATE PROCEDURE f_borrow AS
SELECT 类别,SUM(总数) 借阅次数
FROM Book_info
GROUP BY 类别
ORDER BY SUM(总数) 
--执行格式
--EXEC f_borrow

--添加新书方式
CREATE PROCEDURE INPUTBOOK
@书号 VARCHAR(10),@序列号 VARCHAR(10),@书名 VARCHAR(30),@作者 VARCHAR(20),
@出版社 VARCHAR(20),@出版年份 CHAR(10),@价格 MONEY,@分类号 CHAR(10),
@入藏时间 DATETIME,@位置 VARCHAR(20)
AS BEGIN 
INSERT INTO BOOK VALUES(@书号,@书名,@作者,@出版社,@价格,@分类号,@出版年份)
INSERT INTO INDEXNO VALUES(@书号,@序列号,@书号+@序列号)
INSERT INTO Copy VALUES(@书号+@序列号,@入藏时间,'未借出',@位置)
END
--调用格式
--EXEC INPUTBOOKA '书号','序列号','书名','作者','出版社(已知)','出版年份','价格','分类号(已知)','(时间)','位置' 

--添加副本
CREATE PROCEDURE INPUTCOPY
@书号 CHAR(10),@序列号 VARCHAR(20),
@入藏时间 DATETIME,@位置 VARCHAR(20)
AS BEGIN 
INSERT INTO INDEXNO VALUES(@书号,@序列号,@书号+@序列号)
INSERT INTO Copy VALUES(@书号+@序列号,@入藏时间,'未借出',@位置)
END
--调用格式
--EXEC INPUTCOPY '(已知)','','(时间)',''

/***********趣味榜单***********/
/*************个人*************/
--榜单1：个人借阅次数最多的书
CREATE PROCEDURE User_borrow_max_person
@用户号 CHAR(10)
AS BEGIN
SELECT 书名,COUNT(书名) 借阅次数
FROM User_borrow_info
WHERE 用户号 = @用户号
GROUP BY 书名
HAVING COUNT(书名)>= ALL(
SELECT COUNT(书名) 借阅次数
FROM User_borrow_info
WHERE 用户号 = @用户号
GROUP BY 书名)
END
--调用格式
--EXEC User_borrow_max_person '用户名'

--榜单2：个人归还最快的书
CREATE PROCEDURE User_borrow_minutes_min
@用户号 CHAR(10)
AS BEGIN 
SELECT 书名,MIN(DATEDIFF(minute,出借时间,实归还时间)) 分钟
FROM User_borrow_info
WHERE 状态 = '已归还' AND 用户号 = @用户号
GROUP BY 书名
HAVING MIN(DATEDIFF(minute,出借时间,实归还时间))<=ALL(
SELECT MIN(DATEDIFF(minute,出借时间,实归还时间))
FROM User_borrow_info
WHERE 状态 = '已归还' AND 用户号 = @用户号
GROUP BY 书名)
END
--调用格式
--EXEC User_borrow_minutes_min '用户名'

/**********全体***********/
--榜单3：被借次数最多的书
CREATE PROCEDURE Total_book_borrow_num_max AS
SELECT 书名,类别,作者,出版社,MAX(历史借阅数) 借阅次数
FROM Book_info
GROUP BY 书名,类别,作者,出版社
HAVING MAX(历史借阅数)>= ALL(
SELECT MAX(历史借阅数)
FROM Book_info
GROUP BY 书名,类别,作者,出版社
HAVING MAX(历史借阅数) IS NOT NULL)
--调用格式
--EXEC Total_book_borrow_num_max

--榜单4：借书次数最多的用户
CREATE PROCEDURE Total_user_borrow_num_max AS 
SELECT d_uno 用户号,MAX(total_borrow_num) 借阅次数
FROM User_borrow_num
WHERE total_borrow_num IS NOT NULL
GROUP BY d_uno
HAVING MAX(total_borrow_num) >= ALL(
SELECT MAX(total_borrow_num)
FROM User_borrow_num
WHERE total_borrow_num IS NOT NULL
GROUP BY d_uno)
--调用格式
--EXEC Total_user_borrow_num_max

--榜单5：最受喜爱类别
CREATE PROCEDURE f_borrow_max AS
SELECT 类别,SUM(总数) 借阅次数
FROM Book_info
GROUP BY 类别
HAVING SUM(总数) >=ALL(
SELECT SUM(总数) 借阅次数
FROM Book_info
GROUP BY 类别)
--执行格式
--EXEC f_borrow_max

/*****************前端两模块调用语句*********************/
/***********管理员（增删改查）***********/
--注册用户
--INSERT INTO UserList VALUES('','','','普通用户','',null,null)
--例：('111111'（用户号）,'zys'（用户名）,'普通用户'（用户类型）,'15638594562'（电话号码）,后两个由触发器生成)

--更改用户密码
--UPDATE UserList SET u_password  = '' WHERE u_no = ''

--增加出版社记录
--INSERT INTO Publish VALUES ('出版社名','地点','联系方式')
--例：INSERT INTO Publish VALUES('清华大学出版社', '北京', '15236948788')

--增加书籍分类记录
--INSERT INTO FClassify VALUES ('分类号','分类名','位置')
--例：INSERT INTO FClassify VALUES ('A','教材', '1F-A')

--增加新书记录
--EXEC INPUTBOOKA '书号','序列号','书名','作者','出版社(已知)','出版年份','价格','分类号(已知)','(时间)','位置' （已知含义为填入数据在表中已存在）
--增加副本记录
--EXEC INPUTCOPY '书号','序列号','(时间)','位置'

--增加借阅记录
--INSERT INTO Databorrow VALUES('','','2020','2020','0',null)
--例：INSERT INTO Databorrow VALUES('0000101'（索引号）,'111111'（用户号）,'2020','2020','0',null)

--增加归还记录（能否做按钮）
--UPDATE DataBorrow SET d_state = '已归还' WHERE d_ino = '' AND d_uno = '' AND d_lenddate = ''

--删除某本书所有副本（需逐条执行！！！）
--ALTER TABLE dbo.DataBorrow NOCHECK CONSTRAINT ALL
--DELETE FROM Book WHERE b_no = ''
--ALTER TABLE dbo.DataBorrow CHECK CONSTRAINT ALL

--删除仅删除某一副本书录,指定索书号
--ALTER TABLE dbo.DataBorrow NOCHECK CONSTRAINT ALL
--DELETE FROM Copy WHERE c_ino = ''
--ALTER TABLE dbo.DataBorrow CHECK CONSTRAINT ALL

--更改用户记录,指定用户号
--改用户类型（需逐条执行！！！）
--ALTER TABLE dbo.UserType NOCHECK CONSTRAINT ALL
--UPDATE UserList SET u_type = '' WHERE u_no = ''
--ALTER TABLE dbo.UserType CHECK CONSTRAINT ALL

--查询用户信息
--管理员查看所有用户信息
--SELECT * FROM User_info 
--管理员查看指定用户信息
--SELECT * FROM User_info WHERE 用户号 = ''

--查询用户借阅信息
--管理员查看所有借阅信息
--SELECT * FROM User_borrow_info
--管理员/用户查看指定用户借阅信息
--SELECT * FROM User_borrow_info WHERE  User_borrow_info.用户号 = ''

--查看已有馆藏图书
--SELECT * FROM Book_info
--查看所有书籍馆内状态
--SELECT * FROM Book_borrow_info
--查看指定书籍馆内状态，指定关键字
--SELECT * FROM Book_borrow_info WHERE 书名 LIKE '%(关键字段)%'

/***********用户（增查改）***********/
--注册用户
--INSERT INTO UserList VALUES('','','普通用户','',null,null)
--例：('111111'（用户号）,'zys'（用户名）,'普通用户（默认）','15638594562'（电话号码）,后两个由触发器生成)

--查看自身用户信息
--SELECT * FROM User_info WHERE 用户号 = '(自身用户号)'

--查看自身用户借阅记录
--SELECT * FROM User_borrow_info WHERE  User_borrow_info.用户号 = '(自身用户号)'

--用户查看已有馆藏图书
--SELECT * FROM Book_info

--用户查看所有书籍馆内状态
--SELECT * FROM Book_borrow_info

--查看指定书籍馆内状态，指定关键字
--SELECT * FROM Book_borrow_info WHERE 书名 LIKE '%(关键字段)%'

--更改用户记录,指定用户号
--改用户名
--UPDATE UserList SET u_name = '' WHERE u_no = ''
--改电话号码
--UPDATE UserList SET u_phone = '' WHERE u_no = ''

