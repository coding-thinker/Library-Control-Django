from django.shortcuts import render
from django.http import HttpResponse
from django.http import HttpResponseRedirect
from demo.dbconnect import dbconn
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages


@csrf_exempt
def default(request):
    role = request.POST.get("role", None)
    user = request.POST.get("user", None)
    pwd = request.POST.get("pwd", None)
    conn = dbconn()
    conn.connect()
    if role == "librarian":
        if conn.exec("SELECT COUNT(*) FROM Adimistration WHERE a_no = '%s'" % user)[0][0] != 0:
            if conn.exec("SELECT a_password FROM Adimistration WHERE a_no = '%s'" % user)[0][0] == pwd:
                return HttpResponseRedirect("/%s/%s" % (role, user))
    elif role == "reader":
        if conn.exec("SELECT COUNT(*) FROM UserList WHERE u_no = '%s'" % user)[0][0] != 0:
            if conn.exec("SELECT u_password FROM UserList WHERE u_no = '%s'" % user)[0][0] == pwd:
                return HttpResponseRedirect("/%s/%s" % (role, user))
    messages.error(request, '用户名或密码不正确')
    conn.close()
    return HttpResponseRedirect("/")


# Create your views here.
