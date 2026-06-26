abstract class BaseMapper<Model, Dto> {
  Model toModel(Dto dto);
}
