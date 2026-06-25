import os
import pymysql
import time
import boto3
from flask import Flask, render_template, request, redirect
from urllib.parse import urlparse

app = Flask(
    __name__,
    template_folder=""
)

s3 = boto3.client("s3", region_name="ap-northeast-1")

def get_db_connection():
    return pymysql.connect(
        host=os.environ.get("DB_HOST"),
        user=os.environ.get("DB_USER"),
        password=os.environ.get("DB_PASSWORD"),
        database=os.environ.get("DB_NAME"),
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route("/")
def index():
    return "Hello Flask"

@app.route("/form")
def form():
    print("GET /form");
    return render_template("form.html")

@app.route("/users")
def users():
    print("GET /users")

    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM users")
            results = cursor.fetchall()

        html = "<h1>ユーザー一覧</h1>"

        for user in results:
            image_html = ""
            if user.get("image_url"):
                image_html = f'<img src="{user["image_url"]}" width="200"><br>'

            html += f"""
            <div style="margin-bottom:20px;">
              <p>ID: {user["id"]}</p>
              <p>名前: {user["name"]}</p>
              <p>メール: {user["email"]}</p>
              {image_html}
              <a href="/edit/{user["id"]}">編集</a>

              <form action="/delete/{user["id"]}" method="POST" style="display:inline;">
                <button type="submit">削除</button>
              </form>
              <hr>
            </div>
            """

        return html

    finally:
        conn.close()

@app.route("/add", methods=["POST"])
def add_user():
    name = request.form.get("name")
    email = request.form.get("email")
    image = request.files.get("image")

    image_url = None

    print(f"POST /add name={name} email={email}")

    if image and image.filename:
        bucket = os.environ.get("S3_BUCKET_NAME")

        key = f"images/{int(time.time() * 1000)}-{image.filename}"

        s3.upload_fileobj(
            image,
            bucket,
            key,
            ExtraArgs={
                "ContentType": image.content_type
            }
        )

        image_url = f"https://{bucket}.s3.ap-northeast-1.amazonaws.com/{key}"

        print(f"UPLOAD file={image.filename} url={image_url}")

    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO users (name, email, image_url) VALUES (%s, %s, %s)",
                (name, email, image_url)
            )

        conn.commit()

    except Exception as e:
        print("DB Error:", e)
        return "DB Error", 500

    finally:
        conn.close()

    return redirect("/users")

@app.route("/edit/<int:id>")
def edit(id):

    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute( "SELECT * FROM users WHERE id = %s", (id,) )
            user = cursor.fetchone()

        if user is None:
            return "User not found", 404

        html = f"""
        <form action="/update/{user["id"]}" method="POST">
          名前: <input type="text" name="name" value="{user["name"]}"><br>
          メール: <input type="text" name="email" value="{user["email"]}"><br>
          <button type="submit">更新</button>
        </form>
        """

        return html

    except Exception as e:
        print("DB Error:", e)
        return "DB Error", 500

    finally:
        conn.close()

@app.route("/update/<int:id>", methods=["POST"])
def update(id):
    name = request.form.get("name")
    email = request.form.get("email")

    print(f"POST /update name={name} email={email}")

    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "UPDATE users SET name = %s, email = %s WHERE id = %s",
                (name, email, id)
            )

        conn.commit()

    except Exception as e:
        print("DB Error:", e)
        return "DB Error", 500

    finally:
        conn.close()

    return redirect("/users")

@app.route("/delete/<int:id>", methods=["POST"])
def delete(id):
    print(f"POST /delete id={id}")

    conn = get_db_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute( "SELECT * FROM users WHERE id = %s", (id,) )
            user = cursor.fetchone()

        if user is None:
            return "User not found", 404

        image_url = user["image_url"]

        if image_url:
            key = urlparse(image_url).path.lstrip("/")
            bucket = os.environ.get("S3_BUCKET_NAME")

            s3.delete_object(
                Bucket=bucket,
                Key=key
            )

        with conn.cursor() as cursor:
            cursor.execute( "DELETE FROM users WHERE id = %s", (id,) )

        conn.commit()

    except Exception as e:
        import traceback

        print("DELETE Error:", e)
        traceback.print_exc()

        return "DELETE Error", 500

    finally:
        conn.close()

    return redirect("/users")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)