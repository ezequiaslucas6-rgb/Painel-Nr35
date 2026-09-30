-- =====================================================================
-- Torna a sua conta INSTRUTOR (rode depois de criar o usuário no painel
-- do Supabase: Authentication > Users > Add user). Troque o e-mail abaixo
-- pelo e-mail que você usou ao criar esse usuário.
-- Para ter mais de um instrutor, rode de novo trocando o e-mail.
-- =====================================================================
do $$
declare
  v_email text := 'ezequiaslucas6@gmail.com';
  v_id    uuid;
begin
  select id into v_id from auth.users where lower(email) = lower(trim(v_email));
  if v_id is null then
    raise exception 'Usuário % não encontrado. Crie-o antes em Authentication > Users > Add user (marque "Auto Confirm User").', v_email;
  end if;
  insert into public.admins (user_id) values (v_id) on conflict do nothing;
end $$;

-- Conferência: deve listar o(s) e-mail(s) de instrutor.
select a.user_id, u.email from public.admins a join auth.users u on u.id = a.user_id;
