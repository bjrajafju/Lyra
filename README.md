Requisitos mínimos do projeto:
Requer Node.js 18+ (npm incluído)
Download: https://nodejs.org

Requer Flutter SDK 3.x (com Dart incluído)
Download: https://docs.flutter.dev/get-started/install



Para correr o projeto, seguir os seguintes passos:
Abrir o terminal (cmd) na base do projeto (pasta que contém este ficheiro)
Colar os 3 seguintes comandos:

cd backend
npm install
npm run dev

Deixar esse terminal aberto, pois está a correr o backend do site.


Abrir outro terminal na base do projeto
Colar os 3 seguintes comandos:
cd frontend
flutter pub get
flutter run

Quando aparecer a pergunta "Please choose one (or "q" to quit):" deve precionar a tecla:
'2' --> se quiser abrir em website;
'1' --> se quiser abrir em windows app;



O ficheiro .env ja tem as credenciais necessárias, e a base de dados está a ser hosted no supabase, então não é necessário importar nada, o projeto deve começar sem problemas.
