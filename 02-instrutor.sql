-- =====================================================================
-- Torna a sua conta INSTRUTOR (rode depois de criar o usuário no painel
-- do Supabase: Authentication > Users > Add user). Troque o e-mail abaixo
-- pelo e-mail que você usou ao criar esse usuário.
-- =====================================================================
insert into public.admins (user_id)
select id from auth.users where email = 'ezequiaslucas6@gmail.com'
on conflict do nothing;

-- Conferência: deve listar 1 linha com o seu e-mail.
select a.user_id, u.email from public.admins a join auth.users u on u.id = a.user_id;
