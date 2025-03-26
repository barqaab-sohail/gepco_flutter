import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/utils/extensions.dart';
import 'package:get/get.dart';
import 'package:gepco_front_flutter/controllers/login_controller.dart';
import 'package:gepco_front_flutter/widgets/custom_form_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final loginController = Get.put(LoginController());
  final _formKey = GlobalKey<FormState>();
  String? email, password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Login Page', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'images/mono.png',
                      fit: BoxFit.cover,
                      height: 100,
                      width: 100,
                    ),
                  ),
                  const SizedBox(height: 60),

                  CustomFormField(
                    hintText: 'email',
                    controller: loginController.emailController,
                    validator: (val) {
                      if (!val!.isValidEmail) {
                        return 'Enter a valid Email';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      setState(() {
                        email = val;
                      });
                    },
                  ),
                  CustomFormField(
                    hintText: 'password',
                    controller: loginController.passwordController,
                    obscureText: true,
                    validator: (val) {
                      if (!val!.isValidPassword) {
                        return 'Enter a valid Password';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      setState(() {
                        password = val;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children: [
                      Row(
                        children: [
                          Obx(
                            () => Checkbox(
                              value: loginController.rememberMe.value,
                              onChanged:
                                  (value) =>
                                      loginController.rememberMe.value = value!,
                            ),
                          ),
                          Text("Remember Me"),
                        ],
                      ),

                      FloatingActionButton(
                        onPressed:
                            () => {
                              loginController.isLoading.value = true,
                              if (_formKey.currentState!.validate())
                                {
                                  _formKey.currentState!.save(),

                                  loginController.loginWithGetx(),
                                }
                              else
                                {loginController.isLoading.value = false},
                              //loginController.loginWithGetx()
                            },
                        backgroundColor: Colors.blue,
                        hoverColor: Colors.grey,
                        child: Obx(
                          () =>
                              loginController.isLoading.value
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text("Login"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
