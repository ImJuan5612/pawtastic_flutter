# 📘 Detalles del Proyecto Pawtastic

Este documento proporciona una visión técnica profunda de la aplicación **Pawtastic**, una solución integral para la gestión de mascotas y servicios relacionados.

## 🏗 Arquitectura del Proyecto

El proyecto sigue una arquitectura limpia y modular basada en Flutter, organizada para facilitar la escalabilidad y el mantenimiento.

### Estructura de Directorios (`lib/`)

-   **`config/`**: Configuraciones globales de la app.
    -   `app_theme.dart`: Definiciones de tema (colores, tipografía).
    -   `supabase_config.dart`: Inicialización y configuración del cliente Supabase.
-   **`models/`**: Modelos de datos que representan las entidades del negocio (Mascotas, Usuarios, Servicios, etc.).
-   **`providers/`**: Gestión de estado utilizando el patrón `Provider`.
    -   `auth_provider.dart`: Lógica de autenticación y sesión de usuario.
    -   `pet_provider.dart`: Gestión de datos de las mascotas.
    -   `hotel_provider.dart`: Lógica para reservas y servicios de hotel.
    -   `payment_provider.dart`: Manejo de pagos y transacciones.
    -   `service_catalog_provider.dart`: Catálogo de servicios disponibles.
-   **`screens/`**: Pantallas de la interfaz de usuario.
    -   `auth/`: Pantallas de Login y Registro.
    -   `main/`: Pantalla principal y navegación.
    -   `pets/`: Perfiles y edición de mascotas.
    -   `wallet/`: Billetera digital y métodos de pago.
    -   `settings/`: Configuraciones de usuario.
-   **`services/`**: Lógica de negocio y comunicación con APIs externas.
    -   `connectivity_service.dart`: Monitoreo de conexión a internet.
-   **`widgets/`**: Componentes UI reutilizables (Botones, Tarjetas, Inputs).

## 🛠 Stack Tecnológico

### Core
-   **Flutter**: SDK principal para desarrollo multiplataforma.
-   **Dart**: Lenguaje de programación.

### Backend & Base de Datos
-   **Supabase**: Plataforma Backend-as-a-Service (BaaS) utilizada para:
    -   **Autenticación**: Gestión de usuarios segura.
    -   **Base de Datos**: PostgreSQL en tiempo real para almacenar datos de usuarios, mascotas y servicios.
    -   **Storage**: Almacenamiento de imágenes (fotos de perfil, mascotas).

### Gestión de Estado
-   **Provider**: Inyección de dependencias y gestión de estado reactiva.

### UI & UX
-   **Google Fonts**: Tipografías modernas.
-   **Flutter SVG**: Renderizado de gráficos vectoriales.
-   **Lottie**: Animaciones vectoriales de alta calidad.
-   **Shimmer**: Efectos de carga (esqueletos).
-   **Animate Do**: Animaciones de entrada para widgets.
-   **Table Calendar / Syncfusion Calendar**: Gestión de fechas y reservas.

### Utilidades
-   **Connectivity Plus**: Detección de estado de red.
-   **Image Picker / Cropper**: Selección y edición de imágenes.
-   **Intl**: Internacionalización y formateo de fechas.
-   **UUID**: Generación de identificadores únicos.

## 🔑 Características Clave

### 1. Autenticación Robusta
Implementada con `Supabase Auth`, permite a los usuarios registrarse e iniciar sesión de forma segura. El estado de la sesión se persiste y gestiona a través de `AuthProvider`.

### 2. Gestión de Mascotas
Los usuarios pueden crear perfiles detallados para sus mascotas, incluyendo fotos, raza, edad y necesidades especiales. Esto se gestiona mediante `PetProvider` y se almacena en la base de datos.

### 3. Servicios y Reservas
La aplicación ofrece un catálogo de servicios (Hotel, Guardería, Spa, etc.). Los usuarios pueden explorar estos servicios y realizar reservas. `HotelProvider` maneja la lógica de disponibilidad y reservas.

### 4. Billetera Digital (Wallet)
Integración de un sistema de billetera para gestionar métodos de pago y visualizar historial de transacciones, facilitado por `PaymentProvider`.

### 5. Modo Offline / Conectividad
La aplicación monitorea la conexión a internet mediante `ConnectivityService` y adapta la interfaz para informar al usuario sobre el estado de la red.

## 🚀 Configuración y Despliegue

### Requisitos Previos
-   Flutter SDK instalado (versión compatible con `^3.6.1`).
-   Cuenta en Supabase y proyecto configurado.

### Configuración de Variables de Entorno
Asegúrate de tener las credenciales de Supabase configuradas en `lib/config/supabase_config.dart` (o mediante variables de entorno si se implementa esa mejora):

```dart
const supabaseUrl = 'TU_SUPABASE_URL';
const supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
```

### Ejecución
Para correr el proyecto en modo debug:

```bash
flutter pub get
flutter run
```
