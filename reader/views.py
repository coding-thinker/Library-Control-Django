from django.shortcuts import render
from django.http import HttpResponse
from django.http import HttpResponseRedirect
from demo.settings import BASE_DIR
from demo.dbconnect import dbconn
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages


def verify(*avgs):
    for each in avgs:
        if each == '':
            return False
    return True


def clear(iter):
    result0 = []
    for i in range(len(iter)):
        result1 = []
        for j in range(len(iter[i])):
            if type(iter[i][j]) != str and iter[i][j] is not None:
                result1.append(str(iter[i][j]))
            elif iter[i][j] is None:
                result1.append('N/A')
            else:
                result1.append(iter[i][j])
        result0.append(result1)
    return result0


@csrf_exempt
def default(request, user):
    if request.method == 'POST':
        job = request.POST.get("job", None)

        conn = dbconn()
        conn.connect()
        table = 0
        if job == "user_info":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='User_info') order by colorder")]
            data = conn.exec("SELECT * FROM User_info WHERE 用户号 = '%s'" % user)
            table = 1
        elif job == "user_borrow_info":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='User_borrow_info') order by colorder")]
            data = conn.exec("SELECT * FROM User_borrow_info WHERE  User_borrow_info.用户号 = '%s'" % user)
            table = 1
        elif job == "all_book":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='Book_info') order by colorder")]
            data = conn.exec("SELECT * FROM Book_info")
            table = 1
        elif job == "all_borrow":
            titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='Book_borrow_info') order by colorder")]
            data = conn.exec("SELECT * FROM Book_borrow_info")
            table = 1
        elif job == "one_borrow":
            avg1 = request.POST.get("avg1", None)
            if verify(avg1):
                titles = [i[0] for i in conn.exec("select name from syscolumns where id=(select max(id) from sysobjects where xtype='v' and name='Book_borrow_info') order by colorder")]
                data = conn.exec("SELECT * FROM Book_borrow_info WHERE 书名 LIKE '%" + avg1 + "%'")
                table = 1
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "edit_number":
            avg2 = request.POST.get("avg2", None)
            if verify(avg2):
                conn.do("UPDATE UserList SET u_phone = '%s' WHERE u_no = '%s'" % (avg2, user))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        elif job == "User_borrow_max_person":
            titles = ["书名", "借阅次数"]
            data = conn.exec("EXEC User_borrow_max_person '%s'" % user)
            table = 1
        elif job == "User_borrow_minutes_min":
            titles = ["书名", "分钟"]
            data = conn.exec("EXEC User_borrow_minutes_min '%s'" % user)
            table = 1
        elif job == "Total_book_borrow_num_max":
            titles = ["书名", "类别", "作者", "出版社", "借阅次数"]
            data = conn.exec("EXEC Total_book_borrow_num_max")
            table = 1
        elif job == "Total_user_borrow_num_max":
            titles = ["用户号", "借阅次数"]
            data = conn.exec("EXEC Total_user_borrow_num_max")
            table = 1
        elif job == "f_borrow":
            titles = ["类别", "借阅次数"]
            data = conn.exec("EXEC  f_borrow")
            table = 1
        elif job == "edit_pwd":
            avg3 = request.POST.get("avg3", None)
            if verify(avg3):
                conn.do("UPDATE UserList SET u_password  = '%s' WHERE u_no = '%s'" % (user, avg3))
                messages.error(request, '完成')
                table = 0
            else:
                messages.error(request, '值不能为空')
                table = 0
        conn.close()
        if table:
            dic = {"user": user, 'titles': titles, "data": clear(data), "table": table}
        else:
            dic = {"user": user, "table": table}
        return render(request, BASE_DIR + '/reader/templates/reader.html', dic)

    else:
        return render(request, BASE_DIR + '/reader/templates/reader.html', {"user": user})
