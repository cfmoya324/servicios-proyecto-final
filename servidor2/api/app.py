from flask import Flask, jsonify
from flask_mysql_connector import MySQL
import datetime

app = Flask(__name__)

# Configuración de conexión MySQL (para VM2)
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'flaskuser2'
app.config['MYSQL_PASSWORD'] = 'flaskpass2'
app.config['MYSQL_DATABASE'] = 'api_vm2'

mysql = MySQL(app)

# Endpoint principal: devuelve información del servidor
@app.route('/api/info')
def get_info():
    cursor = mysql.connection.cursor(dictionary=True)
    cursor.execute("SELECT * FROM info_servidor ORDER BY id DESC LIMIT 1;")
    data = cursor.fetchone()
    cursor.close()

    # Agrega un timestamp actual para monitoreo
    data['timestamp'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return jsonify(data)

# Endpoint secundario: permite actualizar el estado
@app.route('/api/actualizar')
def update_status():
    cursor = mysql.connection.cursor()
    cursor.execute("""
        UPDATE info_servidor
        SET mensaje='Actualizado dinámicamente desde API',
            fecha_actualizacion=NOW()
        WHERE id=1;
    """)
    mysql.connection.commit()
    cursor.close()
    return jsonify({"status": "actualizado", "servidor": "VM2"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)