# Implementación de un Clúster de servidores Web con Balanceo de Carga utilizando Apache, Flask, MySQL y Vagrant

Desarrollado por Isabella Castañeda, Andrés Felipe Cardona, Juan David Velasco, David Alejandro Sanchez, y Camilo Franco Moya.

### Cómo utilizar el proyecto

- Para crear y provisionar las máquinas virtuales ejecutar:

    ```
    $ vagrant up
    ```

- Para cambiar el algoritmo del balancer modificar el archivo `/etc/apache2/sites-available/000-servidor1.conf` y cambiar la opción:

    ```
    ProxySet lbmethod={algoritmo}
    ```
    
- Para ejecutar los tests de Artillery, ir a su respectiva carpeta y ejecutar:

    ```
    $ artillery run {archivo de test}
    ```

### Imágenes

![cluster funcionando](/screenshots/cluster-funcionando.png)
