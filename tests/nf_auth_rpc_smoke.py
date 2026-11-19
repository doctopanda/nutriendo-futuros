#!/usr/bin/env python3
"""NUTRIENDO FUTUROS · NF-E2E-2026-005
Automated real-Auth RPC authorization smoke tests. Python standard library only.
No patient identifiers, access tokens or passwords are printed or saved.
Read-only: never invokes mutation RPCs.
Usage:
  export NF_SUPABASE_URL='https://<project-ref>.supabase.co'
  export NF_PUBLISHABLE_KEY='sb_publishable_...'
  export NF_MAESTRO_EMAIL='...' NF_MAESTRO_PASSWORD='...'
  export NF_ESTATAL_EMAIL='...' NF_ESTATAL_PASSWORD='...'
  export NF_SUPERVISOR_EMAIL='...' NF_SUPERVISOR_PASSWORD='...'
  export NF_PROMOTOR_EMAIL='...' NF_PROMOTOR_PASSWORD='...'
  python3 tests/nf_auth_rpc_smoke.py
Passwords must remain in local environment or a secret manager, NEVER in Git.
The script makes actual login requests and should only run when authorized.
"""
import json
import os
import sys
import urllib.error
import urllib.request

BASE = os.environ.get("NF_SUPABASE_URL", "").rstrip("/")
KEY = os.environ.get("NF_PUBLISHABLE_KEY", "")
ROLES = {
    "MAESTRO": "admin_maestro",
    "ESTATAL": "admin_estatal",
    "SUPERVISOR": "supervisor_distrital",
    "PROMOTOR": "promotor_salud",
}
SENSITIVE_MAP_KEYS = {
    "nombre", "curp", "telefono", "direccion", "municipio", "localidad", "clues",
    "cuidador", "fecha_nacimiento", "claves_identidad",
}
results = []

class HttpError(Exception):
    def __init__(self, status, text):
        super().__init__(f"HTTP {status}")
        self.status = status
        self.text = text

def request(path, key, payload, bearer=None):
    data = json.dumps(payload, separators=(",", ":")).encode()
    headers = {
        "apikey": key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    if bearer:
        headers["Authorization"] = "Bearer " + bearer
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as exc:
        # Do not show error bodies: they could include details from production.
        raise HttpError(exc.code, "") from None

def record(role, name, outcome, detail=""):
    results.append((role, name, outcome, detail))
    print(f"{role:10s} {name:28s} {outcome:6s} {detail}")

def rpc(token, function, args):
    return request("/rest/v1/rpc/" + function, KEY, args, token)

def denied(token, function, args):
    try:
        rpc(token, function, args)
    except HttpError as exc:
        return exc.status in (401, 403, 400)
    return False

def main():
    if not BASE.startswith("https://") or not KEY:
        print("ERROR: configure NF_SUPABASE_URL (HTTPS) and NF_PUBLISHABLE_KEY.")
        return 2
    for label, expected in ROLES.items():
        email = os.environ.get("NF_" + label + "_EMAIL", "")
        password = os.environ.get("NF_" + label + "_PASSWORD", "")
        if not email or not password:
            record(label, "credentials", "SKIP", "Missing environment variables")
            continue
        try:
            login = request("/auth/v1/token?grant_type=password", KEY,
                            {"email": email, "password": password})
            token = login["access_token"]
        except (HttpError, KeyError, ValueError) as exc:
            record(label, "auth_login", "FAIL", type(exc).__name__)
            continue
        record(label, "auth_login", "PASS")
        try:
            profile = rpc(token, "nf_mi_perfil", {})
            if isinstance(profile, list):
                profile = profile[0] if profile else {}
            actual = profile.get("rol", profile.get("role", "")) if isinstance(profile, dict) else ""
            district = profile.get("distrito_id") if isinstance(profile, dict) else None
            if actual != expected:
                record(label, "expected_role", "FAIL", "Account role does not match test")
                continue
            record(label, "expected_role", "PASS")
            rows = rpc(token, "nf_folios_para_mapa", {"p_distrito": None, "p_limite": 200})
            if not isinstance(rows, list):
                record(label, "map_response", "FAIL", "Expected list")
                continue
            exposed = any(bool(set(item) & SENSITIVE_MAP_KEYS) for item in rows)
            record(label, "map_minimal_fields", "FAIL" if exposed else "PASS")
            if district is not None:
                if not 1 <= int(district) <= 6:
                    record(label, "district_scope", "FAIL", "Invalid district")
                else:
                    scope_ok = all(int(item.get("distrito_id", 0)) == int(district) for item in rows)
                    record(label, "district_scope", "PASS" if scope_ok else "FAIL")
                    other = 1 if int(district) != 1 else 2
                    foreign = rpc(token, "nf_folios_para_mapa",
                                  {"p_distrito": other, "p_limite": 200})
                    record(label, "foreign_district_empty",
                           "PASS" if foreign == [] else "FAIL")
            else:
                record(label, "district_scope", "SKIP", "Global role")
            folio = rows[0].get("folio") if rows else "NF-DS6-99999999"
            can_nominal = expected in ("admin_maestro", "admin_estatal")
            if can_nominal and not rows:
                record(label, "nominal_access", "SKIP", "No permitted folios")
            elif can_nominal:
                result = rpc(token, "nf_datos_para_envio", {"p_folio": folio})
                record(label, "nominal_access", "PASS" if isinstance(result, dict) and result.get("folio") == folio else "FAIL")
            else:
                ok = denied(token, "nf_datos_para_envio", {"p_folio": folio})
                record(label, "nominal_denied", "PASS" if ok else "FAIL")
            if expected == "admin_maestro":
                out = rpc(token, "nf_listar_blackbox", {"p_limite": 1})
                record(label, "blackbox_access", "PASS" if isinstance(out, list) else "FAIL")
            else:
                ok = denied(token, "nf_listar_blackbox", {"p_limite": 1})
                record(label, "blackbox_denied", "PASS" if ok else "FAIL")
            if expected in ("supervisor_distrital", "promotor_salud"):
                ok = denied(token, "nf_listar_bitacora",
                            {"p_limite": 1, "p_usuario": None, "p_accion": None})
                record(label, "admin_audit_denied", "PASS" if ok else "FAIL")
        except (HttpError, ValueError, TypeError, KeyError) as exc:
            record(label, "rpc_suite", "FAIL", type(exc).__name__)
    print("\nSUMMARY (no identity, folios or clinical data disclosed)")
    from collections import Counter
    counts = Counter(row[2] for row in results)
    print(" ".join(f"{name}={counts[name]}" for name in ("PASS", "FAIL", "SKIP")))
    return 1 if counts["FAIL"] else (3 if counts["SKIP"] else 0)

if __name__ == "__main__":
    sys.exit(main())
