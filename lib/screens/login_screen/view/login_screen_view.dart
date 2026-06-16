import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/app_color/app_color.dart';
import '../../../widget/global_widgets/global_button.dart';
import '../../../widget/global_widgets/global_text_form_field.dart';
import '../view_model/login_screen_view_model.dart';

class LoginScreenView extends StatelessWidget {
  const LoginScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<LoginProvider>();
    final read = context.read<LoginProvider>();
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<LoginProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                  child: Stack(
                    children: [
                      // Background Gradient
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryLight,
                              AppColors.primaryLight.withOpacity(0.7),
                              Colors.blue.shade300,
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30.r),
                            bottomRight: Radius.circular(30.r),
                          ),
                        ),
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.end,
                      //   children: [
                      //     Padding(
                      //       padding:  EdgeInsets.only(top: 20.w,right: 20.w),
                      //       child: Image.asset("assets/images/srit-india-logo.webp",width: 80.w,height: 40.w,),
                      //     ),
                      //   ],
                      // ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 34.w, vertical: 30.h),
                        child: Form(
                          key: provider.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 40.h),


                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(20.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                 child:  Center(child: Padding(
                                   padding: const EdgeInsets.all(20.0),
                                   child: Image.asset("assets/images/srit-india-logo.webp",width: 80.w,height: 40.w,),
                                 )),
                                ),
                              ),
                              SizedBox(height: 32.h),

                              // Welcome Text
                              Center(
                                child: Text(
                                  "Welcome to PMS App",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28.sp,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              // SizedBox(height: 8.h),
                              // Center(
                              //   child: Text(
                              //     "Sign in to continue",
                              //     style: TextStyle(
                              //       fontSize: 14.sp,
                              //       color: Colors.white.withOpacity(0.9),
                              //       fontWeight: FontWeight.w400,
                              //     ),
                              //   ),
                              // ),
                              SizedBox(height: 40.h),

                              // White Card for Form
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(24.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Error Message
                                    if (provider.error != null)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 20.h),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 12.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 18.sp,
                                              color: Colors.red.shade700,
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: Text(
                                                provider.error!,
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => provider.clearError(),
                                              child: Container(
                                                padding: EdgeInsets.all(4.w),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 14.sp,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Email Field
                                    GlobalTextFormField(
                                      controller: watch.userNameController,
                                      labelText: "UserName",
                                      hintText: "Enter your UserName",
                                      isRequired: true,
                                      textInputAction: TextInputAction.next,
                                      validator: provider.validateEmail,
                                      prefixIcon: Icon(
                                        Icons.person,
                                        size: 20.sp,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),

                                    // Password Field
                                    GlobalTextFormField(
                                      controller: watch.passwordController,
                                      labelText: "Password",
                                      hintText: "Enter your password",
                                      isRequired: true,
                                      isPassword: !provider.isPasswordVisible,
                                      textInputAction: TextInputAction.done,
                                      validator: provider.validatePassword,
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        size: 20.sp,
                                        color: AppColors.primaryLight,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          provider.isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          size: 20.sp,
                                          color: Colors.grey.shade500,
                                        ),
                                        onPressed: () => provider.togglePasswordVisibility(),
                                      ),
                                      onFieldSubmitted: (_) async {
                                        await provider.login(context);
                                      },
                                    ),

                                    SizedBox(height: 32.h),

                                    // Login Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54.h,
                                      child: GlobalButton(
                                        onPressed: () {
                                          read.login(context);
                                        },
                                        text: 'Login',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    SizedBox(height: 20.h),

                                    // Decorative Footer
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade200,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                                          child: Icon(
                                            Icons.fingerprint,
                                            size: 20.sp,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade200,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16.h),

                                    // Footer Text
                                    Center(
                                      child: Text(
                                        "Secure login with encryption",
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20.h),

                              // Version Text
                              Center(
                                child: Text(
                                  "Version 1.0.0",
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}