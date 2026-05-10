FROM public.ecr.aws/bitnami/moodle:latest

# Copie des plugins personnalisés
# On les place dans /opt/bitnami/moodle car c'est le répertoire source de Bitnami
COPY --chown=1001:1001 plugins/ /opt/bitnami/moodle/

# Si vous avez des thèmes, ils iront aussi dans /opt/bitnami/moodle/theme/ via la structure de votre dossier plugins
