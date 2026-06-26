import os
import pymysql

# DB接続
def get_db_connection():
    return pymysql.connect(
        host=os.environ.get("DB_HOST"),
        user=os.environ.get("DB_USER"),
        password=os.environ.get("DB_PASSWORD"),
        database=os.environ.get("DB_NAME"),
        cursorclass=pymysql.cursors.DictCursor
    )

# ユーザ一覧取得
def get_users():
    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM users")
            return cursor.fetchall()

    finally:
        conn.close()

# ユーザ情報取得
def get_user(id):
    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute( "SELECT * FROM users WHERE id = %s", (id,) )
            return cursor.fetchone()

    finally:
        conn.close()

# ユーザ情報登録
def insert_user(name, email, image_url):
    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO users (name, email, image_url) VALUES (%s, %s, %s)",
                (name, email, image_url)
            )

        conn.commit()

    finally:
        conn.close()

# ユーザ情報更新
def update_user(id, name, email):
    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "UPDATE users SET name = %s, email = %s WHERE id = %s",
                (name, email, id)
            )

        conn.commit()

    finally:
        conn.close()

# ユーザ情報削除
def delete_user(id):
    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute( "DELETE FROM users WHERE id = %s", (id,) )

        conn.commit()

    finally:
        conn.close()
