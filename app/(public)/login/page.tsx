export default function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-xl shadow-sm border p-8">
          <div className="mb-8">
            <h1 className="text-2xl font-semibold text-gray-900">Sign in to EMS</h1>
            <p className="text-sm text-gray-500 mt-1">Enter your credentials to continue</p>
          </div>
          {/* LoginForm component will be added in M1 */}
          <p className="text-center text-sm text-gray-400">Login form — coming in Milestone 1</p>
        </div>
      </div>
    </div>
  )
}
