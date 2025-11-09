from flask import Flask, Blueprint, request, jsonify, render_template
from flask_sqlalchemy import SQLAlchemy
import datetime

app = Flask(__name__)

# Configuración de conexión MySQL
class Config:
    MYSQL_HOST = 'localhost'
    MYSQL_USER = 'vm_user'
    MYSQL_PASSWORD = 'vm_pass'
    MYSQL_DB = 'api_vm'
    SQLALCHEMY_DATABASE_URI = f'mysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}/{MYSQL_DB}'

app.config.from_object(Config)

db = SQLAlchemy()
db.init_app(app)

class Info_servidor(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    servidor = db.Column(db.String(50), nullable=False)
    ip = db.Column(db.String(20), nullable=False)
    rol = db.Column(db.String(50), nullable=False)
    estado = db.Column(db.String(20), nullable=False)
    mensaje = db.Column(db.String(100), nullable=False)
    fecha_actualizacion = db.Column(db.TIMESTAMP(), nullable=False)

    def __init__(self, servidor, ip, rol, estado, mensaje):
        self.servidor = servidor
        self.ip = ip
        self.rol = rol
        self.estado = estado
        self.mensaje = mensaje

data_controller = Blueprint('data_controller', __name__)

# Endpoint principal: devuelve información del servidor
@data_controller.route('/api/info', methods=['GET'])
def get_info():
    data = Info_servidor.query.get_or_404(1)
    return jsonify({'servidor': data.servidor, 'ip': data.ip, 'rol': data.rol, 'estado': data.estado, 'mensaje': data.mensaje, 'fecha_actualizacion': data.fecha_actualizacion})

# Endpoint secundario: permite actualizar el estado
@data_controller.route('/api/actualizar', methods=['PATCH'])
def update_status():
    old_data = Info_servidor.query.get_or_404(1)
    old_data.mensaje = 'Actualizado dinámicamente desde API'
    db.session.commit()
    return jsonify({"status": "actualizado"})

# Endpoint secundario: permite actualizar el estado
@data_controller.route('/api/actualizar_frase', methods=['PATCH'])
def update_phrase():
    old_data = Info_servidor.query.get_or_404(1)
    new_data = request.json
    old_data.mensaje = new_data['mensaje']
    db.session.commit()
    return jsonify({"status": "actualizado"})

app.register_blueprint(data_controller)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/health')
def health():
    return render_template('health.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
