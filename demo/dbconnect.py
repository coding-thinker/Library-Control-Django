import pymssql


class EmptyInfo(Exception):
    def __init__(self, *args):
        self.args = args


class dbconn(object):
    def __init__(self, server='DERLAPTOP',db='', user='', pwd=''):
        self.server = server
        self.db = db
        self.user = user
        self.pwd = pwd
        self.connection = None
        self.cursor = None
        if not self.server or not self.db or not self.user or not self.pwd:
            raise EmptyInfo('Error Info on server, user or password')
        if (type(self.server), type(self.db), type(self.user), type(self.pwd)) != (str, str, str, str):
            raise EmptyInfo('Error Info on server, user or password')

    def set_server_db(self, server='', db=''):
        self.server = server
        self.db = db
        if not self.server or not self.db:
            raise EmptyInfo('Error Info on server, user or password')
        if (type(self.server), type(self.db)) != (str, str):
            raise EmptyInfo('Error Info on server, user or password')

    def set_user_pwd(self, user='', pwd=''):
        self.user = user
        self.pwd = pwd
        if not self.user or not self.pwd:
            raise EmptyInfo('Error Info on server, user or password')
        if (type(self.user), type(self.pwd)) != (str, str):
            raise EmptyInfo('Error Info on server, user or password')

    def connect(self):
        if self.connection is not None:
            self.connection.close()
        self.connection = pymssql.connect(host=self.server, user=self.user, password=self.pwd, database=self.db, autocommit = True)
        self.cursor = self.connection.cursor()

    def exec(self, sql):
        self.cursor.execute(sql)
        return self.cursor.fetchall()
    
    def do(self, sql):
        self.cursor.execute(sql)

    def doing(self, sql):
        self.cursor.execute(sql)
        self.connection.commit()

    def close(self):
        if self.cursor is not None and self.connection is not None:
            self.cursor.close()
            self.connection.close()
            self.cursor = None
            self.connection = None
