import application/context.{type Context, AuthContext}
import application/use_cases/import_recipe_use_case.{
  ImportRecipeUseCasePort, ScrapingFailed,
}
import application/use_cases/upsert_recipe_use_case.{UpsertRecipeUseCasePort}
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import infrastructure/errors.{WebsiteNotSupported}
import infrastructure/repositories/recipe_repository
import presentation/rest/decoders
import presentation/rest/encoders
import presentation/rest/middlewares
import wisp.{type Request, type Response}
import youid/uuid

pub fn list(req: Request, ctx: Context) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)

  case recipe_repository.find_all(user_id, ctx.pool) {
    Ok(recipes) ->
      json.array(recipes, encoders.encode_recipe)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn show(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use recipe_id <- middlewares.require_uuid(id)

  case recipe_repository.find_by_id_with_details(recipe_id, user_id, ctx.pool) {
    Ok(Some(recipe_details)) ->
      encoders.encode_recipe_details(recipe_details)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Ok(None) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn create(req: Request, ctx: Context) -> Response {
  use auth_ctx <- middlewares.require_auth(req, ctx)
  use json <- wisp.require_json(req)

  case decoders.decode_recipe_details_upsert_request(json) {
    Ok(decoded) -> {
      case
        upsert_recipe_use_case.execute(
          UpsertRecipeUseCasePort(uuid.v4(), decoded),
          auth_ctx,
        )
      {
        Ok(recipe_details) ->
          encoders.encode_recipe_details(recipe_details)
          |> json.to_string_builder
          |> wisp.json_response(201)
        Error(upsert_recipe_use_case.ValidationFailed(error)) -> {
          wisp.log_debug(string.inspect(error))
          wisp.unprocessable_entity()
        }
        Error(error) -> {
          wisp.log_error(string.inspect(error))
          wisp.internal_server_error()
        }
      }
    }
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.unprocessable_entity()
    }
  }
}

pub fn update(req: Request, ctx: Context, id: String) -> Response {
  use auth_ctx <- middlewares.require_auth(req, ctx)
  use recipe_id <- middlewares.require_uuid(id)
  use json <- wisp.require_json(req)

  case decoders.decode_recipe_details_upsert_request(json) {
    Ok(decoded) -> {
      case
        upsert_recipe_use_case.execute(
          UpsertRecipeUseCasePort(recipe_id, decoded),
          auth_ctx,
        )
      {
        Ok(recipe_details) ->
          encoders.encode_recipe_details(recipe_details)
          |> json.to_string_builder
          |> wisp.json_response(200)
        Error(upsert_recipe_use_case.ValidationFailed(error)) -> {
          wisp.log_debug(string.inspect(error))
          wisp.unprocessable_entity()
        }
        Error(error) -> {
          wisp.log_error(string.inspect(error))
          wisp.internal_server_error()
        }
      }
    }
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.unprocessable_entity()
    }
  }
}

pub fn delete(req: Request, ctx: Context, id: String) -> Response {
  use AuthContext(user_id, _) <- middlewares.require_auth(req, ctx)
  use recipe_id <- middlewares.require_uuid(id)

  case recipe_repository.delete(recipe_id, user_id, ctx.pool) {
    Ok(True) -> wisp.no_content()
    Ok(False) -> wisp.not_found()
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.internal_server_error()
    }
  }
}

pub fn import_from_url(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  case decoders.decode_import_recipe_request(json) {
    Ok(decoded) -> {
      case
        import_recipe_use_case.execute(
          ImportRecipeUseCasePort(url: decoded.url),
          ctx,
        )
      {
        Ok(scraped_recipe) ->
          encoders.encode_scraped_recipe(scraped_recipe)
          |> json.to_string_builder
          |> wisp.json_response(200)
        Error(ScrapingFailed(WebsiteNotSupported(url))) -> {
          wisp.log_debug("Website not supported: " <> url)
          wisp.unprocessable_entity()
        }
        Error(error) -> {
          wisp.log_error(string.inspect(error))
          wisp.internal_server_error()
        }
      }
    }
    Error(error) -> {
      wisp.log_error(string.inspect(error))
      wisp.unprocessable_entity()
    }
  }
}
