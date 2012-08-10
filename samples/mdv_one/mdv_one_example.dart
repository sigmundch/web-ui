#import('dart:html');
#import('../../watcher.dart');
#import('../../tools/lib/data_template.dart');
#import('mdv_one_views.tmpl.dart');

/**
 * Here is the JS MDV sample code that this Dart template sample was created.
 *
 * <!DOCTYPE html>
 * <html>
 *   <head>
 *     <title>Forms Validation</title>
 *     <script src="include.js"></script>
 *   </head>
 *   <body data-controller="FormController">
 *     <form>
 *       <template instantiate>
 *         <button disabled="{{ invalid }}">Submit</button><br>
 *         Email <input type="text" value="{{ email }}"><br>
 *         Repeat Email: <input type="text" value="{{ repeatEmail }}"><br>
 *         <input type="checkbox" checked="{{ agreeToTerms }}"> I agree
 *         <button disabled="{{ invalid }}">Submit</button>
 *       </template>
 *     </form>
 *
 *     <script>
 * function FormController(root) {
 *   var model = root.computedModel;
 *   function checkValid() {
 *     model.invalid = !model.agreeToTerms ||
 *                     !model.email ||
 *                     model.email != model.repeatEmail;
 *   }
 *
 *   Model.observe(model, 'email', checkValid);
 *   Model.observe(model, 'repeatEmail', checkValid);
 *   Model.observe(model, 'agreeToTerms', checkValid);
 *   checkValid();
 * }
 *
 * FormController.prototype = {
 * };
 *
 * document.body.model = {};
 *     </script>
 *   </body>
 * </html>
 */


class MyModel {
  String email;
  String repeatEmail;
  bool agree;
  bool invalid;

  MyModel() : email = "", repeatEmail = "", agree = false, invalid = true;
}

class FormController implements BaseController {
  MyModel _model;

  FormController() : _model = new MyModel() {
    // Hook up listeners to run application logic when model changes.
    watch(() => model.email, (_) { appLogic(); });
    watch(() => model.repeatEmail, (_) { appLogic(); });
    watch(() => model.agree, (_) { appLogic(); });
  }

  MyModel get model() => _model;

  /**
   * My application logic.
   */
  void appLogic() {
    model.invalid = model.email != null && !model.email.isEmpty() &&
        model.repeatEmail != null && !model.repeatEmail.isEmpty() ?
        model.email != model.repeatEmail : true;
    model.invalid = model.invalid || !model.agree;

    // Debugging code.
    print("in checkValid ${model.email} == ${model.repeatEmail}, agree=${
      model.agree}, invalid=${model.invalid}");
  }
}

var app = null;

void main() {
  app = new MyApplication(new FormController());

  // TODO(terry): Ugly hookup...
  document.body.elements.add(app.display());
}