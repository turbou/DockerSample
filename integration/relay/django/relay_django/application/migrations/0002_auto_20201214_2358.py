# Generated by Django 2.2.13 on 2020-12-14 23:58

import django.core.validators
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('application', '0001_initial'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='backlog',
            options={'verbose_name': 'Backlog', 'verbose_name_plural': 'Backlog List'},
        ),
        migrations.AlterModelOptions(
            name='gitlab',
            options={'verbose_name': 'Gitlab', 'verbose_name_plural': 'Gitlab List'},
        ),
        migrations.AlterModelOptions(
            name='gitlablib',
            options={'verbose_name': 'Gitlab Library', 'verbose_name_plural': 'Gitlab Libraries'},
        ),
        migrations.AlterModelOptions(
            name='gitlabnote',
            options={'verbose_name': 'Gitlab Vulnerability Note', 'verbose_name_plural': 'Gitlab Vulnerability Notes'},
        ),
        migrations.AlterModelOptions(
            name='gitlabvul',
            options={'verbose_name': 'Gitlab Vulnerability', 'verbose_name_plural': 'Gitlab Vulnerabilities'},
        ),
        migrations.AlterModelOptions(
            name='googlechat',
            options={'verbose_name': 'GoogleChat', 'verbose_name_plural': 'GoogleChat List'},
        ),
        migrations.AlterField(
            model_name='backlog',
            name='issuetype_id',
            field=models.CharField(max_length=10, verbose_name='Category ID'),
        ),
        migrations.AlterField(
            model_name='backlog',
            name='name',
            field=models.CharField(max_length=20, unique=True, validators=[django.core.validators.RegexValidator(message='名前は半角英数字、アンスコ4文字〜20文字です。', regex='^[A-Za-z0-9_]{4,20}$')], verbose_name='Name'),
        ),
        migrations.AlterField(
            model_name='backlog',
            name='priority_id',
            field=models.CharField(max_length=1, verbose_name='Priority ID'),
        ),
        migrations.AlterField(
            model_name='backlog',
            name='project_id',
            field=models.CharField(max_length=10, verbose_name='Project ID'),
        ),
        migrations.AlterField(
            model_name='gitlab',
            name='name',
            field=models.CharField(max_length=20, unique=True, validators=[django.core.validators.RegexValidator(message='名前は半角英数字、アンスコ4文字〜20文字です。', regex='^[A-Za-z0-9_]{4,20}$')], verbose_name='Name'),
        ),
        migrations.AlterField(
            model_name='gitlablib',
            name='contrast_app_id',
            field=models.CharField(max_length=36, verbose_name='Application ID'),
        ),
        migrations.AlterField(
            model_name='gitlablib',
            name='contrast_lib_id',
            field=models.CharField(blank=True, max_length=40, null=True, verbose_name='Library ID'),
        ),
        migrations.AlterField(
            model_name='gitlablib',
            name='contrast_lib_lg',
            field=models.CharField(blank=True, max_length=20, null=True, verbose_name='Library Language'),
        ),
        migrations.AlterField(
            model_name='gitlablib',
            name='contrast_org_id',
            field=models.CharField(max_length=36, verbose_name='Organization ID'),
        ),
        migrations.AlterField(
            model_name='gitlablib',
            name='gitlab_issue_id',
            field=models.PositiveSmallIntegerField(verbose_name='Issue IID'),
        ),
        migrations.AlterField(
            model_name='gitlabnote',
            name='contrast_note_id',
            field=models.CharField(max_length=36, unique=True, verbose_name='Contrast Note ID'),
        ),
        migrations.AlterField(
            model_name='gitlabnote',
            name='created_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='Created'),
        ),
        migrations.AlterField(
            model_name='gitlabnote',
            name='creator',
            field=models.CharField(max_length=200, verbose_name='Creator'),
        ),
        migrations.AlterField(
            model_name='gitlabnote',
            name='gitlab_note_id',
            field=models.PositiveSmallIntegerField(verbose_name='Gitlab Note ID'),
        ),
        migrations.AlterField(
            model_name='gitlabnote',
            name='note',
            field=models.TextField(verbose_name='Note'),
        ),
        migrations.AlterField(
            model_name='gitlabnote',
            name='updated_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='Updated'),
        ),
        migrations.AlterField(
            model_name='gitlabnote',
            name='vul',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notes', related_query_name='note', to='application.GitlabVul', verbose_name='Gitlab Vulnerability'),
        ),
        migrations.AlterField(
            model_name='gitlabvul',
            name='contrast_app_id',
            field=models.CharField(max_length=36, verbose_name='Application ID'),
        ),
        migrations.AlterField(
            model_name='gitlabvul',
            name='contrast_org_id',
            field=models.CharField(max_length=36, verbose_name='Organization ID'),
        ),
        migrations.AlterField(
            model_name='gitlabvul',
            name='contrast_vul_id',
            field=models.CharField(blank=True, max_length=19, null=True, verbose_name='Vulnerability ID'),
        ),
        migrations.AlterField(
            model_name='gitlabvul',
            name='gitlab_issue_id',
            field=models.PositiveSmallIntegerField(verbose_name='Issue IID'),
        ),
        migrations.AlterField(
            model_name='googlechat',
            name='name',
            field=models.CharField(max_length=20, unique=True, validators=[django.core.validators.RegexValidator(message='名前は半角英数字、アンスコ4文字〜20文字です。', regex='^[A-Za-z0-9_]{4,20}$')], verbose_name='Name'),
        ),
    ]