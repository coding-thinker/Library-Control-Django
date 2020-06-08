from django.shortcuts import render
from django.http import HttpResponse
from demo.settings import BASE_DIR


def default(request):
    return render(request, BASE_DIR + "/welcome/templates/Welcome.html")
    # return render(request, r"C:\Users\Doctor\Desktop\demo\welcome\templates\Welcome.html")


# Create your views here.
