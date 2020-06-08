from django.shortcuts import render
from django.http import HttpResponse
from django.http import HttpResponseRedirect
from demo.settings import BASE_DIR
from demo.dbconnect import dbconn
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages
from datetime import datetime


def clear(iter):
    result0 = []
    for i in range(len(iter)):
        result1 = []
        for j in range(len(iter[i])):
            if type(iter[i][j]) != str:
                result1.append(str(iter[i][j]))
            else:
                result1.append(iter[i][j])
        result0.append(result1)
    return result0


def verify(*avgs):
    for each in avgs:
        if each == '':
            return False
    return True


@csrf_exempt
def default(request, user):
    if request.method == 'POST':
        table = 0
        conn = dbconn()
        conn.connect()

        job = request.POST.get("job", None)

        if job == "select_all_users":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='User_info') order by colorder")]
            data = conn.exec("SELECT * FROM User_info ")
            table = 1
        elif job == "select_user":
            u_account = request.POST.get("用户号", None)
            if verify(u_account):
                titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='User_info') order by colorder")]
                data = conn.exec("SELECT * FROM User_info WHERE 用户号 = '%s'" % u_account)
                table = 1
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == 'register':
            u_no = request.POST.get("u_no", None)
            u_name = request.POST.get("u_name", None)
            u_password = request.POST.get("u_password", None)
            u_type = request.POST.get("u_type", None)
            u_phone = request.POST.get("u_phone", None)
            if verify(u_no, u_name, u_password, u_type, u_phone):
                conn.do("INSERT INTO UserList VALUES('%s','%s','%s','%s','%s',null,null);" % (u_no, u_name, u_password, u_type, u_phone))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "edit_pwd":
            u_no = request.POST.get("u_no", None)
            u_password = request.POST.get("u_password", None)
            if verify(u_no, u_password):
                conn.do("UPDATE UserList SET u_password  = '%s' WHERE u_no = '%s'" % (user, u_password))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "select_all_press":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='u' and name='Publish') order by colorder")]
            titles = ['出版社名称', '所在地', '联系电话']
            data = conn.exec("SELECT * FROM Publish")
            table = 1
        elif job == "add_press":
            p_name = request.POST.get("p_name", None)
            p_address = request.POST.get("p_address", None)
            p_phone = request.POST.get("p_phone", None)
            if verify(p_name, p_address, p_phone):
                conn.do("INSERT INTO Publish VALUES ('%s','%s','%s');" % (p_name, p_address, p_phone))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "select_all_cate":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='u' and name='FClassify') order by colorder")]
            titles = ['分类号', '名称', '位置']
            data = conn.exec("SELECT * FROM FClassify;")
            table = 1
        elif job == "add_cate":
            f_no = request.POST.get("f_no", None)
            f_name = request.POST.get("f_name", None)
            f_location = request.POST.get("f_location", None)
            if verify(f_no, f_name, f_location):
                conn.do("INSERT INTO FClassify VALUES ('%s','%s','%s');" % (f_no, f_name, f_location))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "select_all_books":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='Book_info') order by colorder")]
            data = conn.exec("SELECT * FROM Book_info")
            table = 1
        elif job == "select_book":
            b_name = request.POST.get("书名", None)
            if verify(b_name):
                titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='Book_borrow_info') order by colorder")]
                data = conn.exec("SELECT * FROM Book_borrow_info WHERE 书名 LIKE '%" + b_name + "%'")
                table = 1
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "add_book":
            b_no = request.POST.get("b_no", None)
            i_sno = request.POST.get("i_sno", None)
            b_name = request.POST.get("b_name", None)
            b_author = request.POST.get("b_author", None)
            b_publish = request.POST.get("b_publish", None)
            b_year = request.POST.get("b_year", None)
            b_price = request.POST.get("b_price", None)
            b_fno = request.POST.get("b_fno", None)
            c_enterdate = request.POST.get("c_enterdate", None)
            c_location = request.POST.get("c_location", None)
            if verify(b_no, i_sno, b_name, b_author, b_publish, b_year, b_price, b_fno, c_enterdate, c_location):
                conn.do("EXEC INPUTBOOK '%s','%s','%s','%s','%s','%s','%s','%s','%s','%s';" % (b_no, i_sno, b_name, b_author, b_publish, b_year, b_price, b_fno, c_enterdate, c_location))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "select_all_copy":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='Book_borrow_info') order by colorder")]
            data = conn.exec("SELECT * FROM Book_borrow_info")
            table = 1
        elif job == "add_copy":
            b_no = request.POST.get("b_no", None)
            i_sno = request.POST.get("i_sno", None)
            c_enterdate = request.POST.get("c_enterdate", None)
            c_location = request.POST.get("c_location", None)
            if verify(b_no, i_sno, c_enterdate, c_location):
                conn.do("EXEC INPUTCOPY '%s','%s','%s','%s'; " % (b_no, i_sno, c_enterdate, c_location))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "select_all_borrow":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='User_borrow_info') order by colorder")]
            data = conn.exec("SELECT * FROM User_borrow_info")
            data = clear(data)
            table = 2
        elif job == "select_borrow":
            u_account = request.POST.get("用户号", None)
            if verify(u_account):
                titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='User_borrow_info') order by colorder")]
                data = conn.exec("SELECT * FROM User_borrow_info WHERE  User_borrow_info.用户号 = '%s'" % u_account)
                data = clear(data)
                table = 2
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "borrow":
            d_ino = request.POST.get("d_ino", None)
            d_uno = request.POST.get("d_uno", None)
            if verify(d_ino, d_uno):
                d_lenddate = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')
                d_lenddate = d_lenddate.split('.')[0] + '.' + d_lenddate.split('.')[1][:3]
                d_returndate = d_lenddate
                conn.do("INSERT INTO Databorrow VALUES('%s','%s','%s','%s','0',null); " % (d_ino, d_uno, d_lenddate, d_returndate))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "delete_all_copies":
            b_no = request.POST.get("b_no", None)
            if verify(b_no):
                conn.do("ALTER TABLE dbo.DataBorrow NOCHECK CONSTRAINT ALL; ")
                conn.do("DELETE FROM Book WHERE b_no = '%s'" % b_no)
                conn.do("ALTER TABLE dbo.DataBorrow CHECK CONSTRAINT ALL; ")
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "delete_copy":
            c_no = request.POST.get("c_no", None)
            if verify(c_no):
                conn.do("ALTER TABLE dbo.DataBorrow NOCHECK CONSTRAINT ALL; ")
                conn.do("DELETE FROM Copy WHERE c_ino = '%s'" % c_no)
                conn.do("ALTER TABLE dbo.DataBorrow CHECK CONSTRAINT ALL; ")
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "alter_class":
            u_no = request.POST.get("u_no", None)
            u_type = request.POST.get("u_type", None)
            if verify(u_type, u_no):
                conn.do("ALTER TABLE dbo.UserType NOCHECK CONSTRAINT ALL; ")
                conn.do("UPDATE UserList SET u_type = '%s' WHERE u_no = '%s'" % (u_type, u_no))
                conn.do("ALTER TABLE dbo.UserType CHECK CONSTRAINT ALL; ")
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "return":
            d_ino = request.POST.get("d_ino", None)
            d_uno = request.POST.get("d_uno", None)
            d_lenddate = request.POST.get("d_lenddate", None)
            d_state = request.POST.get("d_state", None)
            if d_state == "已归还":
                messages.error(request, '已经归还 不能重复归还')
            elif d_state == "未归还":
                d_lenddate = d_lenddate.split('.')[0] + '.' + d_lenddate.split('.')[1][:3]
                line = "UPDATE DataBorrow SET d_state = '已归还' WHERE d_ino = '%s' AND d_uno = '%s' AND d_lenddate = '%s'" % (d_ino, d_uno, d_lenddate)
                print(line)
                conn.do("UPDATE DataBorrow SET d_state = '已归还' WHERE d_ino = '%s' AND d_uno = '%s' AND d_lenddate = '%s'" % (d_ino, d_uno, d_lenddate))
                messages.error(request, '完成')
            table = 0

        if table:
            dic = {"user": user, 'titles': titles, "data": data, "table": table}
        else:
            dic = {"user": user}
        return render(request, BASE_DIR + '/librarian/templates/librarian.html', dic)
    else:
        return render(request, BASE_DIR + '/librarian/templates/librarian.html', {"user": user})
# Create your views here.
