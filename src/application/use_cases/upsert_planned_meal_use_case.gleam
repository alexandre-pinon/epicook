import app_logger
import application/context.{type AuthContext}
import application/dto/planned_meal_dto.{
  type PlannedMealUpsertInput, type PlannedMealUpsertRequest,
}
import application/use_cases/upsert_meal_shopping_list_item_use_case.{
  UpsertMealShoppingListItemsUseCasePort,
}
import domain/entities/planned_meal.{type PlannedMeal}
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import infrastructure/postgres/db.{type Transactional}
import infrastructure/repositories/planned_meal_repository
import valid.{type NonEmptyList}
import youid/uuid.{type Uuid}

pub type UpsertPlannedMealUseCasePort {
  UpsertPlannedMealUseCasePort(id: Uuid, data: PlannedMealUpsertRequest)
}

type UpsertPlannedMealUseCaseResult =
  PlannedMeal

pub type UpsertPlannedMealUseCaseErrors {
  ValidationFailed(NonEmptyList(String))
  TransactionFailed(pgo.TransactionError)
}

pub fn execute(
  port: UpsertPlannedMealUseCasePort,
  auth_ctx: AuthContext,
) -> Result(UpsertPlannedMealUseCaseResult, UpsertPlannedMealUseCaseErrors) {
  use validated_input <- result.try(validate_input(port))

  pgo.transaction(
    auth_ctx.ctx.pool,
    upsert_planned_meal(
      planned_meal_id: port.id,
      with: validated_input,
      given: auth_ctx,
    ),
  )
  |> result.map_error(TransactionFailed)
}

fn validate_input(
  port: UpsertPlannedMealUseCasePort,
) -> Result(PlannedMealUpsertInput, UpsertPlannedMealUseCaseErrors) {
  planned_meal_dto.validate_planned_meal_upsert_request(port.data)
  |> result.map_error(ValidationFailed)
}

fn upsert_planned_meal(
  planned_meal_id id: Uuid,
  with input: PlannedMealUpsertInput,
  given auth_ctx: AuthContext,
) -> Transactional(Result(PlannedMeal, String)) {
  fn(transaction: pgo.Connection) {
    use planned_meal <- result.try(
      planned_meal_repository.upsert(
        planned_meal.PlannedMeal(
          ..planned_meal_dto.to_entity(input, auth_ctx.user_id),
          id: id,
        ),
        transaction,
      )
      |> result.replace_error("upsert planned meal failed"),
    )

    case planned_meal.recipe_id {
      Some(recipe_id) ->
        upsert_meal_shopping_list_item_use_case.execute(
          UpsertMealShoppingListItemsUseCasePort(planned_meal, recipe_id),
          context.Context(..auth_ctx.ctx, pool: transaction),
        )
        |> result.map_error(app_logger.log_error)
        |> result.replace_error("upsert meal shopping list items failed")
      None -> Ok(planned_meal)
    }
  }
}
