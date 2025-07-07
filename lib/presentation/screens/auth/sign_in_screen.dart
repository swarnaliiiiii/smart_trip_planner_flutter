import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_trip/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              Navigator.of(context).pushReplacementNamed('/home');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        Icon(Icons.flight_takeoff,
                            color: Color(0xFFFFC107), size: 32.sp),
                        SizedBox(width: 8.w),
                        Text('Itinera AI',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24.sp,
                                color: Color(0xFF2D7D32))),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    Text('Hi, Welcome Back',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22.sp)),
                    SizedBox(height: 8.h),
                    Text('Login to your account',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 15.sp)),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Image.asset('assets/google.png', height: 24.sp),
                        label: Text('Sign in with Google',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                        onPressed: () {
                          context.read<AuthBloc>().add(SignInWithGoogle());
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Center(
                        child: Text('or Sign in with Email',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 14.sp))),
                    SizedBox(height: 24.h),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? 'Password too short'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: Color(0xFF2D7D32),
                        ),
                        Text('Remember me', style: TextStyle(fontSize: 14.sp)),
                        Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: Text('Forgot your password?',
                              style: TextStyle(
                                  color: Colors.red, fontSize: 14.sp)),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthBloc>().add(SignInWithEmail(
                                        email: _emailController.text.trim(),
                                        password:
                                            _passwordController.text.trim(),
                                      ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2D7D32),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Login',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
