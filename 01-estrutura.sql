-- =====================================================================
-- NR-35 online: estrutura do banco (rode UMA vez no SQL Editor do Supabase)
-- =====================================================================

-- 1) Instrutores (administradores). Ninguém altera esta tabela pelo site:
--    só você, pelo SQL Editor (arquivo 02-instrutor.sql).
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.admins enable row level security;
drop policy if exists "admin le o proprio registro" on public.admins;
create policy "admin le o proprio registro" on public.admins
  for select to authenticated using (user_id = auth.uid());

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- 2) Participantes: um registro por colaborador (identificação + progresso).
create table if not exists public.alunos (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  nome           text not null check (length(trim(nome)) >= 5),
  cpf            text not null unique check (cpf ~ '^[0-9]{11}$'),
  email          text not null,
  registered_at  timestamptz not null default now(),
  last_seen      timestamptz,
  current_module text,
  finished_at    timestamptz,
  state          jsonb not null default '{}'::jsonb
);
alter table public.alunos enable row level security;

drop policy if exists "aluno ve o proprio, instrutor ve todos" on public.alunos;
create policy "aluno ve o proprio, instrutor ve todos" on public.alunos
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "aluno cria o proprio registro" on public.alunos;
create policy "aluno cria o proprio registro" on public.alunos
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "aluno atualiza o proprio progresso" on public.alunos;
create policy "aluno atualiza o proprio progresso" on public.alunos
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "instrutor exclui registros" on public.alunos;
create policy "instrutor exclui registros" on public.alunos
  for delete to authenticated using (public.is_admin());

-- Depois de criado, o aluno não consegue trocar nome, CPF, e-mail nem data de registro.
create or replace function public.alunos_protege_identidade()
returns trigger language plpgsql as $$
begin
  if not public.is_admin() and (
       new.nome is distinct from old.nome or new.cpf is distinct from old.cpf or
       new.email is distinct from old.email or new.registered_at is distinct from old.registered_at or
       new.user_id is distinct from old.user_id) then
    raise exception 'Dados de identificação não podem ser alterados.';
  end if;
  return new;
end $$;
drop trigger if exists trg_alunos_protege on public.alunos;
create trigger trg_alunos_protege before update on public.alunos
  for each row execute function public.alunos_protege_identidade();

-- 3) Respostas: uma linha por pergunta respondida (para o painel detalhado).
create table if not exists public.respostas (
  id        bigint generated always as identity primary key,
  user_id   uuid not null references auth.users(id) on delete cascade,
  modulo    text not null,
  pergunta  text not null,
  correta   boolean not null,
  criado_em timestamptz not null default now()
);
create index if not exists respostas_user_idx on public.respostas (user_id, criado_em desc);
alter table public.respostas enable row level security;

drop policy if exists "aluno ve as proprias respostas, instrutor ve todas" on public.respostas;
create policy "aluno ve as proprias respostas, instrutor ve todas" on public.respostas
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "aluno grava as proprias respostas" on public.respostas;
create policy "aluno grava as proprias respostas" on public.respostas
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "instrutor exclui respostas" on public.respostas;
create policy "instrutor exclui respostas" on public.respostas
  for delete to authenticated using (public.is_admin());

-- 4) Permissões de acesso pela API (explícitas, para funcionar em qualquer projeto novo).
grant usage on schema public to authenticated;
grant select on public.admins to authenticated;
grant select, insert, update, delete on public.alunos to authenticated;
grant select, insert, delete on public.respostas to authenticated;
grant execute on function public.is_admin() to authenticated;
